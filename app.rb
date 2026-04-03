require 'sinatra'
require 'slim'
require 'sinatra/reloader'
enable :sessions
also_reload 'model'
require_relative './model.rb'

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

def iteratetimeattempts(timeattempts)
  if timeattempts == nil
    timeattempts = Time.now.to_i.to_s + ","
  else
    timeattempts = timeattempts + Time.now.to_i.to_s + ","
  end

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

  return [timeattempts,first - last]
end

def admincheck()
  if session[:user_state] != "admin"
    session[:error] = "Du är inte admin"
    redirect("/error")
  end
end

before('/') do
  if session[:user_state] != "admin" && session[:user_state] != "user" 
    session[:user_state] = "guest"
  end
end

get('/') do
  slim(:"planeshop/welcomepage")
end

get('/planes') do
  @id = session[:user_id]
  @state = session[:user_state]

  if session[:user_state] == "user"
    slim(:"planeshop/indexuser")
  elsif session[:user_state] == "admin"
    slim(:"planeshop/indexadmin")
  else
    slim(:"planeshop/indexguest")
  end
end

before('/planes/new') do
  admincheck()
end

get("/planes/new") do 
  slim(:"planeshop/new")
end

get("/planes/:typeid") do
  typeid = params[:typeid]

  @planes = planes(typeid)

  if session[:user_state] == "user"
    slim(:"planeshop/showuser")
  elsif session[:user_state] == "admin"
    slim(:"planeshop/showadmin")
  else
    slim(:"planeshop/showguest")
  end
end

before('/planes') do
  if request.post?
    admincheck()
  end
end

post("/planes") do
  name = params[:n]
  description = params[:d]
  price = params[:p]
  topspeed = params[:ts]
  typeid = params[:ty].to_i
  enginetypeid = params[:et].to_i

  if name.length == 0 || description.length == 0 || price.length == 0 || topspeed.length == 0
    session[:error] = "Du måste skriva i alla fälten"
    redirect('/error')
  elsif name.length > 100 || description.length < 10 || description.length > 200
    session[:error] = "Namnet måste vara mellan 1-100 tecken och beskrivning mellan 10-200"
    redirect('/error')
  elsif !price.scan(/\D/).empty? || !topspeed.scan(/\D/).empty?
    session[:error] = "Priset och maxhastighet måste vara heltal, och priset måste vara minst 1 och maxhastighet minst 100"
    redirect('/error')
  elsif price.to_i < 1 || topspeed.to_i < 100
    session[:error] = "Priset måste vara minst 1 och maxhastigheten minst 100"
    redirect('/error')
  end
 
  addplane(name,description,price,topspeed,typeid,enginetypeid)

  redirect('/planes')
end

before('/planes/*/*')do
  admincheck()
end

get('/planes/:id/edit') do
  id = params[:id].to_i

  @selected_plane = selected_plane(id)

  slim(:"planeshop/edit")
end

post('/planes/:id/update') do
  db = db()

  id = params[:id].to_i
  name = params[:n]
  description = params[:d]
  price = params[:p]
  topspeed = params[:ts]
  typeid = params[:ty].to_i
  enginetypeid = params[:et].to_i

  if name.length == 0 || description.length == 0 || price.length == 0 || topspeed.length == 0
    session[:error] = "Du måste skriva i alla fälten"
    redirect('/error')
  elsif name.length > 100 || description.length < 10 || description.length > 200
    session[:error] = "Namnet måste vara mellan 1-100 tecken och beskrivning mellan 10-200"
    redirect('/error')
  elsif !price.scan(/\D/).empty? || !topspeed.scan(/\D/).empty?
    session[:error] = "Priset och maxhastighet måste vara heltal, och priset måste vara minst 1 och maxhastighet minst 100"
    redirect('/error')
  elsif price.to_i < 1 || topspeed.to_i < 100
    session[:error] = "Priset måste vara minst 1 och maxhastigheten minst 100"
    redirect('/error')
  end

  update_plane(id,name,description,price,topspeed,typeid,enginetypeid)

  redirect('/planes')
end

post('/planes/:id/delete') do
  denna_ska_bort = params[:id].to_i
  
  delete(denna_ska_bort)

  redirect('/planes')
end

get('/register') do
  slim(:"planeshop/register")
end

post('/register') do
  name = params[:q]
  password = params[:a]
  confirmpassword = params[:b]

  result=idresult(name)

  if result.empty?
      if name == ""
        session[:error] = "Du skrev inte in ett namn"
        redirect('/error')
      elsif password.length == 0 || confirmpassword.length == 0
        session[:error] = "Du måste skriva i båda lösenordsfälten"
        redirect('/error')
      elsif password.length > 100 || password.length < 10
        session[:error] = "Lösenordet måste ha 10-100 tecken"
        redirect('/error')
      elsif name.length > 100
        session[:error] = "För långt användarnamn"
        redirect('/error')
      end

      if password == confirmpassword
        pwd_digest=pwd_digest(password)
        adduser(name,pwd_digest)
        redirect('/login')
      else
        session[:error] = "Lösenord är inte samma som bekräftelselösenordet"
        redirect("/error")
      end
  else
    session[:error] = "Användarnamnet är taget"
    redirect('/error')
  end
end

get('/login') do
  slim(:"planeshop/login")
end

post('/login') do
  name = params[:q]
  password = params[:a]

  if name.length == 0 || password.length == 0
    session[:error] = "Du måste skriva i båda fälten"
    redirect("/error")
  end

  result = userresult(name)

  if result.empty?
    session[:error] = "Användarnamnet finns inte"
    redirect("/error")
  end

  id = result.first["id"]
  state = result.first["state"]
  pwd_digest = result.first["pwddigest"]
  timeattempts = result.first["timeattempts"]
  timestuff = iteratetimeattempts(timeattempts)
  timedif = timestuff[1]

  if timedif < 30 && countcommas(timestuff[0]) > 4
    session[:error] = "Cool down, stopp där hackerman"
    redirect("/error")
  end

  updatetimeattempts(timestuff[0],id)

  if pwd_digest2(pwd_digest) == password
      session[:user_id] = id
      session[:user_state] = state
      @id = session[:user_id]
      @state = session[:user_state]

      redirect("/planes")
  else
    session[:error] = "Fel lösenord"
    redirect("/error")
  end
end

get('/myplanes/:id') do
  id = session[:user_id]
  idcheck = params[:id].to_i
  p "#{reltable()}"
  if idcheck == id
    @airplanes = myplanes(id)
    slim(:"planeshop/myplanes")
  else
    session[:error] = "Du får inte kolla på en annan users flygplan"
    slim(:"planeshop/error")
  end
end

before('/addplanetouser/:planeid') do
  if session[:user_state] != "user"
    session[:error] = "Du är inte en user"
    redirect("/error")
  end
end

post('/addplanetouser/:planeid') do
  uid = session[:user_id]
  aid = params[:planeid].to_i
  addplanestouser(uid,aid)
  redirect('/planes')
end

post('/clear') do
  session.clear
  redirect('/')
end

get('/error') do
  slim(:"planeshop/error")
end
