require 'sqlite3'

db = SQLite3::Database.new("databas.db")


def seed!(db)
  puts "Using db file: db/todos.db"
  puts "🧹 Dropping old tables..."
  drop_tables(db)
  puts "🧱 Creating tables..."
  create_tables(db)
  puts "🍎 Populating tables..."
  populate_tables(db)
  puts "✅ Done seeding the database!"
end

def drop_tables(db)
  db.execute('DROP TABLE IF EXISTS airplanes')
  db.execute('DROP TABLE IF EXISTS types')
  db.execute('DROP TABLE IF EXISTS enginetypes')
end

def create_tables(db)
  db.execute('CREATE TABLE airplanes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL, 
              description TEXT,
              state BOOLEAN,
              price INTEGER,
              topspeed INTEGER,
              typeid INTEGER,
              enginetypeid INTEGER)')

  db.execute('CREATE TABLE types (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL)')

  db.execute('CREATE TABLE enginetypes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL)')
end

def populate_tables(db)
  db.execute('INSERT INTO airplanes (name, description, state, price, topspeed, typeid, enginetypeid) VALUES ("Draken", "Swedish military plane by Saab very cool",false,5,2000,1,1)')
  db.execute('INSERT INTO types (name) VALUES ("militaryplane")') 
  db.execute('INSERT INTO enginetypes (name) VALUES ("jetafterburner")') 
end


seed!(db)





