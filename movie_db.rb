require 'pg'
require 'rest-client'

class Hollywood
  def initialize
    @db = PG.connect(host: 'localhost', dbname: 'movies_db')
  end

  def get(url)
    response = RestClient.get(url)
    JSON.parse(response)
  end

  def create_tables
      sql = <<-SQL
        CREATE TABLE IF NOT EXISTS movies(
          title VARCHAR,
          id SERIAL PRIMARY KEY
        );
        CREATE TABLE IF NOT EXISTS actors(
          name VARCHAR,
          id SERIAL PRIMARY KEY
        );
        CREATE TABLE IF NOT EXISTS movies_by_actor(
          title VARCHAR,
          actorId INTEGER REFERENCES actors(id),
          id INTEGER
        );
        CREATE TABLE IF NOT EXISTS actors_by_movie(
          name VARCHAR,
          movieId INTEGER REFERENCES movies(id),
          id INTEGER
        )
      SQL

      @db.exec(sql)
  end

  def populate_tables
    create_tables

    movies = get("movies.api.mks.io/movies")
    actors = get("movies.api.mks.io/actors")
    movies_query = []; actors_query = []; movies_id_list = []; actors_id_list = []; actors_by_movie = []; movies_by_actor = []; by_movie_query = []; by_actor_query = []

    movies.each do |movie|
      movies_query << "(\'" + @db.escape_string(movie["title"]) + "\', \'#{movie["id"]}\')"
      movies_id_list << movie["id"]
    end

    @db.exec("INSERT INTO movies VALUES " + movies_query.join(",") + ";")

    actors.each do |actor|
      actors_query << "(\'" + @db.escape_string(actor["name"]) + "\', \'#{actor["id"]}\')"
      actors_id_list << actor["id"]
    end

    @db.exec("INSERT INTO actors VALUES " + actors_query.join(",") + ";")

    movies_id_list.each do |movie_id|
      actors_by_movie << get("movies.api.mks.io/movies/" + movie_id.to_s + "/actors")
    end

    actors_by_movie.flatten.each do |actor|
      by_movie_query << "(\'" + @db.escape_string(actor["name"]) + "\', \'#{actor["movieId"]}\', \'#{actor["id"]}\')"
    end

    @db.exec("INSERT INTO actors_by_movie VALUES " + by_movie_query.join(",") + ";")

    actors_id_list.each do |actor_id|
      movies_by_actor << get("movies.api.mks.io/actors/" + actor_id.to_s + "/movies")
    end

    movies_by_actor.flatten.each do |movie|
      by_actor_query << "(\'" + @db.escape_string(movie["title"]) + "\', \'#{movie["actorId"].to_s}\', \'#{movie["id"].to_s}\')"
    end

    @db.exec("INSERT INTO movies_by_actor VALUES " + by_actor_query.join(",") + ";")
  end

  def all_actors
    sql = <<-SQL
      SELECT name
      FROM actors
      ORDER BY name
    SQL

    puts "All actors sorted by name"
    puts "-------------------------"
    result = @db.exec(sql).each do |actor|
      puts "#{actor["name"]}"
    end
  end

  def all_movies
    sql = <<-SQL
      SELECT title
      FROM movies
      ORDER BY title
    SQL

    puts "All movies sorted by name"
    puts "-------------------------"
    @db.exec(sql).each do |movie|
      puts "#{movie["title"]}"
    end
  end

  def actor_appearances
    sql = <<-SQL
      SELECT DISTINCT a.name, COUNT(m.title)
      FROM movies_by_actor m
      JOIN actors a
      ON m.actorId = a.id
      GROUP BY a.name
      ORDER BY COUNT DESC
    SQL

    puts "Actor | Appearances"
    puts "-------------------------"
    @db.exec(sql).each do |row|
      puts "#{row["name"]} | #{row["count"]}"
    end
  end

  def actors_by_movie(title)
    sql = <<-SQL
      SELECT a.name, m.title
      FROM actors_by_movie a
      JOIN movies m
      ON m.Id = a.movieId
      WHERE title = '#{title}'
    SQL

    puts "Actors in the movie: #{title}"
    puts "-------------------------"
    if @db.exec(sql).cmd_tuples() > 0
      @db.exec(sql).each do |row|
        puts "#{row["name"]}"
      end
    else
      puts "Search returned no results.  View list of all searchable movies with: \'movies\'"
    end
  end

  def movies_by_actor(name)
    sql = <<-SQL
      SELECT a.name, m.title
      FROM movies_by_actor m
      JOIN actors a
      ON a.id = m.actorId
      WHERE name = '#{name}'
    SQL

    puts "Movies for the actor: #{name}"
    puts "-----------------------------"
    if @db.exec(sql).cmd_tuples() > 0
      @db.exec(sql).each do |row|
        puts "#{row["title"]}"
      end
    else
      puts "Search returned no results.  View list of all searchable actors with \'actors\'"
    end
  end

  def co_actors(name)
    movies = []
    co_actors = []

    search = <<-SQL
      SELECT a.name, m.title
      FROM actors_by_movie a
      JOIN movies m
      ON a.movieId = m.id
      WHERE name = '#{name}'
    SQL

    @db.exec(search).each do |movie|
      movies << movie["title"]
    end

    puts "Display all actors that #{name} has co-acted with:"
    puts "--------------------------------------------------"

    movies.each do |movie|
      find = <<-SQL
        SELECT a.name
        FROM actors_by_movie a
        JOIN movies m
        ON a.movieId = m.id
        WHERE title = $1
      SQL

      @db.exec(find, [movie]).each do |actor|
        puts "#{actor["name"]}" unless actor["name"] == "#{name}" || co_actors.include?("#{actor["name"]}")
        co_actors << "#{actor["name"]}"
      end
    end
  end

  def same_movie(name_one, name_two)
    first_actor = []
    first_sql = <<-SQL
      SELECT m.title
      FROM movies_by_actor m
      JOIN actors a
      ON m.actorId = a.id
      WHERE a.name = '#{name_one}'
    SQL
    @db.exec(first_sql).each do |movie|
      first_actor << "#{movie["title"]}"
    end

    second_actor = []
    second_sql = <<-SQL
      SELECT m.title
      FROM movies_by_actor m
      JOIN actors a
      ON m.actorId = a.id
      WHERE a.name = '#{name_two}'
    SQL
    @db.exec(second_sql).each do |movie|
      second_actor << "#{movie["title"]}"
    end

    answer = []
    first_actor.each do |movie|
      answer << movie if second_actor.include?(movie)
    end

    puts "#{name_one} and #{name_two} have acted together in:"
    puts "---------------------------------------------------"
    if answer.length > 0
      answer.each{|x| puts x}
    else 
      puts "No movies. Please try again with a new pair of actors."
    end
  end

  def ui_menu
    puts "################################################################"
    puts "#  Welcome to the Movies Terminal Client!                      #"
    puts "#  Please choose an option:                                    #"
    puts "#    - actors  (see all actors)                                #"
    puts "#    - movies  (see all movies)                                #"
    puts "#    - appearances   (appearances for all actors)              #"
    puts "#    - actors movie  (see all actors for given movie)          #"
    puts "#    - movies actor  (see all movies for given actor)          #"
    puts "#    - co-actors actor  (see all co-actors for given actor)    #"
    puts "#    - same movie  (movies two actors starred in)              #"
    puts "#    - delete  (delete all current tables)                     #"
    puts "#    - populate  (get fresh data, requires delete)             #"
    puts "#    - menu  (display menu)                                    #"
    puts "#    - exit  (exit the user interface)                         #"
    puts "################################################################"
  end

  def movies_ui
    continue = true

    ui_menu

    while continue == true
      puts "Insert selection (case sensitive):"
      input = gets.chomp

      if input == "actors"
        all_actors
      elsif input == "movies"
        all_movies
      elsif input == "appearances"
        actor_appearances
      elsif input.split.first == "actors" && input.split.length > 1
        input = input.split
        input.shift
        actors_by_movie(input.join(" "))
      elsif input.split.first == "movies" && input.split.length > 1
        input = input.split
        input.shift
        movies_by_actor(input.join(" "))
      elsif input.split.first == "co-actors"
        input = input.split
        input.shift
        co_actors(input.join(" "))
      elsif input == "same movie"
        puts "Name One:"
        name_one = gets.chomp
        puts "Name Two:"
        name_two = gets.chomp
        same_movie(name_one, name_two)
      elsif input == "delete"
        @db.exec("DROP TABLE actors, movies, actors_by_movie, movies_by_actor;")
      elsif input == "populate"
        populate_tables
      elsif input == "menu"
        ui_menu
      elsif input == "exit"
        cotinue = false
        break
      end
    end
  end
end

Hollywood.new.movies_ui