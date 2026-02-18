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
  results_as_hash = true

  @militaryplanes = db.execute("SELECT * FROM airplanes WHERE typeid = 1")

  slim(:"planeshop/militaryplanes")
end