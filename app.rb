require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions

def db()
  db = SQLite3::Database.new("db/databas.db")
  db.results_as_hash = true
  return db
end

def countcommas(string)
  i = 0
  count = 0
  while i < string.length
    if string[i] == ","
      count += 1
    end
    i += 1
  end
  return count
end

get('/') do
  if session[:user_state] != "admin" && session[:user_state] != "user" 
    session[:user_state] = "guest"
  end
  slim(:"planeshop/welcomepage")
end

get('/index') do
  @id = session[:user_id]
  @state = session[:user_state]

  if session[:user_state] == "user"
    slim(:"planeshop/indexuser")
  elsif session[:user_state] == "admin"
    slim(:"planeshop/indexadmin")
  else
    slim(:"planeshop/index")
  end
end

get("/index/planes/:typeid") do
  db = db()
  
  typeid = params[:typeid]

  @planes = db.execute("SELECT * FROM airplanes INNER JOIN enginetypes ON airplanes.enginetypeid = enginetypes.eid WHERE typeid = ?",typeid)

  if session[:user_state] == "admin"
    slim(:"planeshop/planesadmin")
  elsif session[:user_state] == "user"
    slim(:"planeshop/planes")
  else
    slim(:"planeshop/planesguest")
  end
end

get("/planes/new") do
  if session[:user_state] == "admin"
    slim(:"planeshop/new")
  else
    session[:error] = "Du är inte admin"
    slim(:"planeshop/error")
  end
end

post("/planes") do
  if session[:user_state] != "admin"
    session[:error] = "Du är inte admin"
    redirect("planeshop/error")
  end

  db = db()

  name = params[:n]
  description = params[:d]
  price = params[:p]
  topspeed = params[:ts]
  type = params[:ty]
  enginetype = params[:et]

  db.execute("INSERT INTO airplanes (name, description, price, topspeed,status,typeid,enginetypeid) VALUES (?,?,?,?,?,?,?)",[name,description,price,topspeed,"I lager",type,enginetype])
  redirect('/index')
end

get('/planes/:id/edit') do
  if session[:user_state] != "admin"
    session[:error] = "Du är inte admin"
    slim(:"planeshop/error")
  end

  db = db()

  id = params[:id].to_i

  @selected_plane = db.execute("SELECT * FROM airplanes WHERE id = ?",id).first

  slim(:"planeshop/edit")
end

post('/planes/:id/update') do
  if session[:user_state] != "admin"
    session[:error] = "Du är inte admin"
    redirect("planeshop/error")
  end

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
  if session[:user_state] != "admin"
    session[:error] = "Du är inte admin"
    redirect("planeshop/error")
  end

  db = db()

  denna_ska_bort = params[:id].to_i

  db.execute("DELETE FROM airplanes WHERE id = ?",denna_ska_bort)
  redirect('/index')
end

get('/myplanes/:id') do
  db = db()

  id = session[:user_id]
  idcheck = params[:id].to_i

  if idcheck == id
    @airplanes = db.execute("SELECT  
    name,description,price,topspeed,enginename,typename
    FROM user_plane_rel 
    INNER JOIN airplanes ON user_plane_rel.id = airplanes.id 
    INNER JOIN enginetypes ON airplanes.enginetypeid = enginetypes.eid 
    INNER JOIN types ON airplanes.typeid = types.tid 
    WHERE uid = ?",[id])
    slim(:"myplanes")
  else
    session[:error] = "Du får inte kolla på en annan users flygplan"
    slim(:"planeshop/error")
  end
end

get('/planeshop/error') do
  slim(:"planeshop/error")
end

post('/adduser') do
  db = db()

  name = params[:q]
  password = params[:a]
  confirmpassword = params[:b]

  result=db.execute("SELECT id FROM users WHERE name=?",name)

  if result.empty?
      if name == ""
        session[:error] = "Du skrev inte in ett namn"
        redirect('/planeshop/error')
      end

      if password == confirmpassword
        pwd_digest=BCrypt::Password.create(password)
        db.execute("INSERT INTO users(name,state,pwddigest,timeattempts) VALUES(?,?,?,?)", [name,"user",pwd_digest,""])
        redirect('/login')
      else
        session[:error] = "Lösenord är inte samma som bekräftelselösenordet"
        redirect("/planeshop/error") #Lösenord är inte samma som confirmpassword
      end
  else
    session[:error] = "Användarnamnet är taget"
    redirect('/planeshop/error')
  end
end

get('/login') do
  slim(:"planeshop/login")
end

get('/register') do
  slim(:"planeshop/register")
end

post('/login') do
  db = db()

  name = params[:q]
  password = params[:a]

  result=db.execute("SELECT id,pwddigest,state,timeattempts FROM users WHERE name=?", name)
  if result.empty?
    session[:error] = "Användarnamnet finns inte"
    redirect("planeshop/error")
  end

  id = result.first["id"]
  timeattempts = result.first["timeattempts"]
  timeattempts = timeattempts + Time.now.to_i.to_s + ","
  if countcommas(timeattempts) > 5
    while timeattempts[0] != ","
      i = 1
      while i < timeattempts.length
        timeattempts[i-1] = timeattempts[i]
        i += 1
      end
      timeattempts[timeattempts.length-1] = ""
    end

    i = 1
    while i < timeattempts.length
      timeattempts[i-1] = timeattempts[i]
      i += 1
    end
    timeattempts[timeattempts.length-1] = ""
  end

  i = 0
  last = ""
  while timeattempts[i] != ","
    last += timeattempts[i]
    i += 1
  end
  last = last.to_i
  i = timeattempts.length-2
  first = ""
  while timeattempts[i] != ","
    first = timeattempts[i] + first
    i -= 1
  end
  first = first.to_i
  timedif = first - last
  if timedif < 30 && countcommas(timeattempts) > 4
    session[:error] = "Cool down, stopp där hackerman"
    redirect("planeshop/error")
  end
  
  db.execute('UPDATE users SET timeattempts=? WHERE id=?', [timeattempts, id])



  state = result.first["state"]
  pwd_digest = result.first["pwddigest"]

  if BCrypt::Password.new(pwd_digest) == password
      session[:user_id] = id
      session[:user_state] = state
      @id = session[:user_id]
      @state = session[:user_state]

      redirect("/index")
  else
    session[:error] = "Fel lösenord"
    redirect("planeshop/error")
  end
end

post('/addplanestouser/:planeid') do
  if session[:user_state] != "user"
    session[:error] = "Du är inte en user"
    redirect("planeshop/error")
  end

  db = db()

  uid = session[:user_id]
  aid = params[:planeid]

  db.execute("INSERT INTO user_plane_rel(uid,id) VALUES (?,?)", [uid,aid])
  db.execute('UPDATE airplanes SET status=? WHERE id=?', ["Såld", aid])
  redirect('/index')
end

get('/clear') do
  session.clear
  slim(:"planeshop/welcomepage")
end