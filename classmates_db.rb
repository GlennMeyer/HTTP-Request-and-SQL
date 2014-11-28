require 'pg'

@db = PG.connect(host: 'localhost', dbname: 'classmates_db')
 
def create_table
  @db.exec("CREATE TABLE classmates(first_name VARCHAR, last_name VARCHAR, twitter_handle VARCHAR, id SERIAL PRIMARY KEY NOT NULL UNIQUE);")
end

def input_record
  continue = true
  query = []

  while continue == true
    array = []
    puts "Enter first name:"
    array << gets.chomp

    puts "Enter last name:"
    array << gets.chomp

    puts "Enter twitter handle:"
    array << gets.chomp

    query << array.join("\',\'")

    puts "Continue? (Y/N):"
    if gets.chomp.downcase == 'n'
      continue = false
      break
    end
  end

  query = query.map{|x| "(\'" + x + "\')"}
  puts query = query.join(",")

  @db.exec("INSERT INTO classmates VALUES " + query + ";")

  # Used for 3 values only
  # sql = <<-SQL
  # INSERT INTO classmates (first_name, last_name, twitter_handle)
  # VALUES $1, $2, $3
  # SQL
  # @db.exec(sql, [first_name, last_name, twitter_handle])
end

def view_record
  result = @db.exec("select * from classmates;")

  puts "| First Name | Last Name | Twitter Handle | Unique ID |"
  result.entries.each {|row| puts "#{row["first_name"]} | #{row["last_name"]} | #{row["twitter_handle"]} | #{row["id"]}"}

  return
end

def delete_record
  puts "Select ID to delete:"
  id = gets.chomp

  # @db.exec("DELETE FROM classmates WHERE id =" + id + ";")
  sql = <<-SQL
  DELETE FROM classmates
  WHERE ID = $1
  SQL
  @db.exec(sql, [id])
end

def update
  puts "Select ID to update:"
  id = gets.chomp

  puts "Insert new first name:"
  first_name = gets.chomp

  puts "Insert new last name:"
  last_name = gets.chomp

  puts "Insert new twitter handle:"
  twitter_handle = gets.chomp
  # @db.exec("UPDATE classmates SET first_name=\'" + first_name + "\', last_name=\'" + last_name + "\', twitter_handle=\'" + twitter_handle + "\' WHERE id =" + id + ";")
  sql = <<-SQL
  UPDATE classmates
  SET first_name= $1, last_name= $2, twitter_handle= $3
  WHERE id= $4
  SQL
  @db.exec(sql [first_name, last_name, twitter_handle, id])
end