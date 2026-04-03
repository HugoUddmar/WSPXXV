require 'bcrypt'
require 'sinatra'
require 'sqlite3'
require 'sinatra/reloader'

def db()
  db = SQLite3::Database.new("db/databas.db")
  db.execute('PRAGMA foreign_keys = ON')
  db.results_as_hash = true
  return db
end

def adduser(name,pwd_digest)
  db.execute("INSERT INTO users(name,state,pwddigest,timeattempts) VALUES(?,?,?,?)", [name,"user",pwd_digest,""])
end

def addplane(name,description,price,topspeed,typeid,enginetypeid)
  db.execute("INSERT INTO airplanes (name,description,status,price,topspeed,typeid,enginetypeid) VALUES (?,?,?,?,?,?,?)",[name,description,"I lager",price,topspeed,typeid,enginetypeid])
end

def planes(typeid)
  return db.execute("SELECT * FROM airplanes INNER JOIN enginetypes ON airplanes.enginetypeid = enginetypes.eid WHERE typeid = ?",typeid)
end

def selected_plane(id)
  return db.execute("SELECT * FROM airplanes WHERE aid = ?",id).first
end

def update_plane(id,name,description,price,topspeed,typeid,enginetypeid)
  db.execute('UPDATE airplanes SET name=?, description=?, price=?, topspeed=?, typeid=?, enginetypeid=? WHERE aid=?', [name,description,price,topspeed,typeid,enginetypeid,id])
end

def delete(denna_ska_bort)
  db.execute("DELETE FROM airplanes WHERE aid = ?",denna_ska_bort)
end

def myplanes(id)
  return db.execute("SELECT  
    name,description,price,topspeed,enginename,typename
    FROM user_plane_rel 
    INNER JOIN airplanes ON user_plane_rel.aid = airplanes.aid 
    INNER JOIN enginetypes ON airplanes.enginetypeid = enginetypes.eid 
    INNER JOIN types ON airplanes.typeid = types.tid 
    WHERE uid = ?",[id])
end

def idresult(name)
  return db.execute("SELECT id FROM users WHERE name=?",name)
end

def userresult(name)
  return db.execute("SELECT id,pwddigest,state,timeattempts FROM users WHERE name=?", name)
end

def pwd_digest(password)
  return BCrypt::Password.create(password)
end

def pwd_digest2(pwd_digest)
  return BCrypt::Password.new(pwd_digest)
end

def addplanestouser(uid,aid)
  db.execute("INSERT INTO user_plane_rel(uid,aid) VALUES (?,?)", [uid,aid])
  db.execute('UPDATE airplanes SET status=? WHERE aid=?', ["Såld", aid])
end

def updatetimeattempts(timeattempts,id)
  db.execute('UPDATE users SET timeattempts=? WHERE id=?', [timeattempts, id])
end