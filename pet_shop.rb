require 'pg'
require 'rest-client'
require 'json'

class Shops
  def initialize
    @db = PG.connect(host: 'localhost', dbname: 'petshop_db')
  end

  def get(url)
    response = RestClient.get(url)
    JSON.parse(response)
  end

  def create_table(name)
    case name
    when "petshops"
      sql = <<-SQL
        CREATE TABLE IF NOT EXISTS #{name} (
          id INTEGER,
          name VARCHAR
        )
      SQL
    when "cats"
      sql = <<-SQL
        CREATE TABLE IF NOT EXISTS  #{name} (
          name VARCHAR,
          adopted VARCHAR,
          id INTEGER,
          shopId INTEGER
        )
      SQL
    when "dogs"
      sql = <<-SQL
        CREATE TABLE IF NOT EXISTS  #{name} (
          name VARCHAR,
          happiness INTEGER,
          adopted VARCHAR,
          id INTEGER,
          shopId INTEGER
        )
      SQL
    end

    @db.exec(sql)
  end

  def populate_petshops
    shops_list = get("pet-shop.api.mks.io/shops")
    query = []
    
    shops_list.each do |shop|
      query << "(\'#{shop["id"].to_s}\', \'" + @db.escape_string(shop["name"]) + "\')"
    end

    query = query.join(",")

    @db.exec("INSERT INTO petshops VALUES " + query + ";")
  end

  def create_shopslist
    shops_list = get("pet-shop.api.mks.io/shops")
    @shop_id_list = []

    shops_list.each do |shop|
      @shop_id_list << "#{shop["id"]}"
    end
  end

  def happiest_dogs
    result = @db.exec("SELECT * FROM dogs WHERE happiness > 4 LIMIT 5;")

    puts "Happiest Dogs:"
    result.each do |row|
      puts "#{row["name"]} - #{row["happiness"]}"
    end
  end

  def populate_cats
    create_shopslist
    shops = []
    query = []

    @shop_id_list.each do |id|
      shops << get("pet-shop.api.mks.io/shops/" + id.to_s + "/cats")
    end

    shops.each do |shop|
      shop.each do |cat|
        cat["name"].gsub!(/[^a-zA-Z]/, "")
        query << "(\'#{cat["name"]}\', \'" + (cat["adopted"].to_s != "true" ? "false" : "#{cat["adopted"].to_s}") + "\', \'#{cat["id"].to_s}\', \'#{cat["shopId"].to_s}\')"
      end
    end

    query = query.join(",")

    @db.exec("INSERT INTO cats VALUES " + query + ";")
  end

  def populate_dogs
    create_shopslist
    shops = []
    query = []

    @shop_id_list.each do |id|
      shops << get("pet-shop.api.mks.io/shops/" + id.to_s + "/dogs")
    end

    shops.each do |shop|
      shop.each do |dog|
        dog["name"].gsub!(/[^a-zA-Z]/, "")
        query << "(\'#{dog["name"]}\', \'#{dog["happiness"].to_s}\', \'" + (dog["adopted"].to_s != "true" ? "false" : "#{dog["adopted"].to_s}") + "\', \'#{dog["id"].to_s}\', \'#{dog["shopId"].to_s}\')"
      end
    end

    query = query.join(",")

    @db.exec("INSERT INTO dogs VALUES " + query + ";")
  end

  def view_all_pets
    # result = @db.exec("SELECT d.name AS name, p.name AS shop FROM petshops p JOIN dogs d ON p.id = d.shopID JOIN cats c ON p.id = c.shopID;")
    # sql = <<-SQL
    #   SELECT c.name, c.shopId FROM cats c
    #   UNION ALL
    #   SELECT d.name, d.shopId FROM dogs d
    #   ORDER BY shopId   
    # SQL
    sql = <<-SQL
      SELECT d.name AS pet_name,
      p.name AS shop_name, 
      'dog' AS type
      FROM dogs d
      JOIN petshops p
      ON d.shopId = p.id
      UNION
      SELECT c.name AS pet_name,
      p.name AS shop_name,
      'cat' AS type
      FROM cats c
      JOIN petshops p
      ON c.shopId = p.id      
    SQL

    result = @db.exec(sql)

    result.entries.each do |row|
      puts "#{row["pet_name"]}, @#{row["shop_name"]}"
    end
  end

  def view_table(name, id=nil)
    case name
    when "petshops"
      result = @db.exec("SELECT * FROM petshops;")
      puts "ID | Name "
      puts "-----------------------------"
      result.entries.each {|row| puts "#{row["id"]} | #{row["name"]}"}
    when "dogs"
      result = @db.exec("SELECT d.name, d.happiness, d.adopted, p.name AS shop FROM dogs d JOIN petshops p ON d.shopId = p.id WHERE shopID = #{id};")
      puts "Dogs in store #{result.entries.first["shop"]}"
      puts "------------------"
      result.entries.each do |row|
        puts "Name: #{row["name"]}"
        puts "Happiness: #{row["happiness"]}"
        puts "Adopted: #{row["adopted"]}"
        puts "------------------"
      end
    end
  end
end