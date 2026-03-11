require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions

def db()
  db = SQLite3::Database.new("db/databas.db")
  return db
end

get('/') do
  slim(:"planeshop/welcomepage")
end

get('/index') do
  if session[:user_state] == ""
    session[:user_state] = "guest"
  end

  @id = session[:user_id]
  @state = session[:user_state]

  if session[:user_state] == "user"
    slim(:"planeshop/indexuser")
  else
    slim(:"planeshop/index")
  end
end

get("/index/planes/:typeid/:state") do
  db = db()
  db.results_as_hash = true
  typeid = params[:typeid]
  state = params[:state]

  @planes = db.execute("SELECT * FROM airplanes INNER JOIN enginetypes ON airplanes.enginetypeid = enginetypes.id WHERE typeid = ?",typeid)

  if state == "admin"
    slim(:"planeshop/planesadmin")
  elsif state == "user"
    slim(:"planeshop/planes")
  else
    slim(:"planeshop/planesguest")
  end
end

get("/planes/new") do
  if session[:user_state] == "admin"
    slim(:"planeshop/new")
  else
    redirect(:"planeshop/error")
  end
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

post('/myplanes/:id') do
  db = db()
  db.results_as_hash = true
  id = session[:user_id]
  idcheck = params[:id].to_i
  if idcheck == id
    @airplanes = db.execute("SELECT * FROM user_plane_rel INNER JOIN airplanes ON user_plane_rel.aid = airplanes.id WHERE uid = ?",[id])
    slim(:"myplanes")
  else
    redirect(:"planeshop/error")
  end
end

get('/planeshop/error') do
  slim(:"planeshop/error")
end

post('/adduser') do
  db = db()

  name = params[:q]
  password = params[:a]
  state = params[:s]
  confirmpassword = params[:b]

  result=db.execute("SELECT id FROM users WHERE name=?",name)

  if result.empty?
      if password == confirmpassword
          pwd_digest=BCrypt::Password.create(password)
          db.execute("INSERT INTO users(name,state,pwddigest) VALUES(?,?,?)", [name,state,pwd_digest])
          redirect('/login')
      else
          redirect(:"planeshop/error") #Lösenord är inte samma som confirmpassword
      end
  else
      redirect('/login')
  end
end

get('/login') do
  slim(:"planeshop/login")
end

get('/register') do
  slim(:"planeshop/register")
end

post('/login') do
  name = params[:q]
  password = params[:a]

  db = db()
  db.results_as_hash = true

  result=db.execute("SELECT id,pwddigest,state FROM users WHERE name=?", name)

  if result.empty?
      redirect(:"planeshop/error")
  end

  id = result.first["id"]
  state = result.first["state"]
  pwd_digest = result.first["pwddigest"]

  if BCrypt::Password.new(pwd_digest) == password
      session[:user_id] = id
      session[:user_state] = state
      @id = session[:user_id]
      @state = session[:user_state]

      if session[:user_state] == "user"
        slim(:"planeshop/indexuser")
      else
        slim(:"planeshop/index")
      end
  else
      redirect(:"planeshop/error") #Fel lösenord/username
  end

end

post('/addplanestouser/:planeid') do
  db = db()
  uid = session[:user_id]
  aid = params[:planeid]
  db.execute("INSERT INTO user_plane_rel(uid,aid) VALUES (?,?)", [uid,aid])
  redirect('/index')
end

get('/clear') do
  session.clear
  slim(:"planeshop/welcomepage")
end