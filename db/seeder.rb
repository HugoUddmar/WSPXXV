require 'sqlite3'

db = SQLite3::Database.new("databas.db")
db.execute('PRAGMA foreign_keys = ON')

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
              aid INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT, 
              description TEXT,
              status TEXT,
              price TEXT,
              topspeed TEXT,
              typeid INT,
              enginetypeid INT)')

  db.execute('CREATE TABLE types (
              tid INTEGER PRIMARY KEY AUTOINCREMENT,
              typename TEXT NOT NULL)')

  db.execute('CREATE TABLE enginetypes (
              eid INTEGER PRIMARY KEY AUTOINCREMENT,
              enginename TEXT NOT NULL)')
  
  db.execute('CREATE TABLE users(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              state TEXT, 
              pwddigest TEXT,
              timeattempts TEXT)')

  db.execute('CREATE TABLE user_plane_rel(
              uid INTEGER,
              aid INTEGER,
              FOREIGN KEY (aid) REFERENCES airplanes(aid) ON DELETE CASCADE)')
end

def populate_tables(db)
  db.execute('INSERT INTO types (typename) VALUES ("militaryplane")') 
  db.execute('INSERT INTO types (typename) VALUES ("airliner")')  
  db.execute('INSERT INTO types (typename) VALUES ("private jet")')
  db.execute('INSERT INTO types (typename) VALUES ("small plane")') 
  db.execute('INSERT INTO enginetypes (enginename) VALUES ("jetafterburner")') 
  db.execute('INSERT INTO enginetypes (enginename) VALUES ("propeller")')

  #db.execute('INSERT INTO airplanes (name,description,status,price,topspeed,typeid,enginetypeid) VALUES ("Draken","Fast delta wing","I lager","100","100",1,1)') 

  db.execute('INSERT INTO users (name,state,pwddigest,timeattempts) VALUES ("Admin","admin","$2a$12$uhiyI6nKW6A2Zdc4eXJJgucMwBOf7A8EHouSB/V1kfXiWyGMg1WUG","")')
end


seed!(db)





