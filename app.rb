require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

def db()
  db = SQLite3::Database.new("db/databas.db")
  return db
end

enable :sessions

get('/') do
  slim(:"planeshop/welcomepage")
end

get('/index') do
  slim(:"planeshop/index")
end

get("/index/militaryplanes") do
  db = db()
  db.results_as_hash = true

  @militaryplanes = db.execute("SELECT * FROM airplanes INNER JOIN enginetypes ON airplanes.enginetypeid = enginetypes.id WHERE typeid = ?",1)

  slim(:"planeshop/militaryplanes")
end

get("/index/airliners") do
  db = db()
  db.results_as_hash = true

  @airliners = db.execute("SELECT * FROM airplanes INNER JOIN enginetypes ON airplanes.enginetypeid = enginetypes.id WHERE typeid = ?",2)

  slim(:"planeshop/airliners")
end

get("/index/privatejets") do
  db = db()
  db.results_as_hash = true

  @privatejets = db.execute("SELECT * FROM airplanes INNER JOIN enginetypes ON airplanes.enginetypeid = enginetypes.id WHERE typeid = ?",3)

  slim(:"planeshop/privatejets")
end

get("/index/smallplanes") do
  db = db()
  db.results_as_hash = true

  @smallplanes = db.execute("SELECT * FROM airplanes INNER JOIN enginetypes ON airplanes.enginetypeid = enginetypes.id WHERE typeid = ?",4)

  slim(:"planeshop/smallplanes")
end

get("/planes/new") do

  slim(:"planeshop/new")
end

post("/planes") do
  db = db()
  db.results_as_hash = true
  name = params[:n]
  description = params[:d]
  price = params[:p]
  topspeed = params[:ts]
  type = params[:ty]
  enginetype = params[:et]

  db.execute("INSERT INTO airplanes (name, description, price, topspeed,typeid,enginetypeid) VALUES (?,?,?,?,?,?)",[name,description,price,topspeed,type,enginetype])
  redirect('/index')
end

get('/planes/:id/edit') do
  db = db()
  db.results_as_hash = true
  id = params[:id].to_i
  @selected_plane = db.execute("SELECT * FROM airplanes WHERE id = ?",id).first

  slim(:"planeshop/edit")
end

post('/planes/:id/update') do
  db = db()

  id = params[:id].to_i
  name = params[:n]
  description = params[:d]
  price = params[:p]
  topspeed = params[:ts]
  type = params[:ty]
  enginetype = params[:et]

  db.execute('UPDATE airplanes SET name=?, description=?, price=?, topspeed=?, typeid=?, enginetypeid=? WHERE id=?', [name, description, price, topspeed, type, enginetype, id])

  redirect('/index')
end

post('/planes/:id/delete') do
  db = db()
  denna_ska_bort = params[:id].to_i
  db.execute("DELETE FROM airplanes WHERE id = ?",denna_ska_bort)
  redirect('/index')
end

get('/user1planes') do
  db = db()
  @airplanes = db.execute("SELECT * FROM user_plane_rel INNER JOIN airplanes ON user_plane_rel.aid = airplanes.id WHERE uid = 2")
end