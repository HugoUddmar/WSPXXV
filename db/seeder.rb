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
  db.execute('DROP TABLE IF EXISTS users')
  db.execute('DROP TABLE IF EXISTS user_plane_rel')
end

def create_tables(db)
  db.execute('CREATE TABLE airplanes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT, 
              description TEXT,
              status TEXT,
              price INTEGER,
              topspeed INTEGER,
              typeid INTEGER,
              enginetypeid INTEGER)')

  db.execute('CREATE TABLE types (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL)')

  db.execute('CREATE TABLE enginetypes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              enginename TEXT NOT NULL)')
  
  db.execute('CREATE TABLE users(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              state TEXT,
              pwddigest TEXT)')

  db.execute('CREATE TABLE user_plane_rel(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              uid INTEGER,
              aid INTEGER)')
end

def populate_tables(db)
  db.execute('INSERT INTO airplanes (name, description, status, price, topspeed, typeid, enginetypeid) VALUES ("Draken", "Swedish military plane by Saab very cool","in stock",5,2000,1,1)')
  db.execute('INSERT INTO airplanes (name, description, status, price, topspeed, typeid, enginetypeid) VALUES ("Cessna 172", "Most popular small plane","in stock",0.2,500,4,2)')
  db.execute('INSERT INTO types (name) VALUES ("militaryplane")') 
  db.execute('INSERT INTO types (name) VALUES ("airliner")')  
  db.execute('INSERT INTO types (name) VALUES ("private jet")')
  db.execute('INSERT INTO types (name) VALUES ("small plane")') 
  db.execute('INSERT INTO enginetypes (enginename) VALUES ("jetafterburner")') 
  db.execute('INSERT INTO enginetypes (enginename) VALUES ("propeller")') 
  db.execute('INSERT INTO users (name,state,pwddigest) VALUES ("AdminKing","admin",1)')
  db.execute('INSERT INTO users (name,state,pwddigest) VALUES ("Airplanebuyer67","user",123)')
  db.execute('INSERT INTO user_plane_rel (uid,aid) VALUES (2,1)')
  db.execute('INSERT INTO user_plane_rel (uid,aid) VALUES (2,2)')
end


seed!(db)





