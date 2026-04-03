require 'sinatra'
require 'slim'
require 'sinatra/reloader'
enable :sessions
also_reload 'model'
require_relative './model.rb'

include Model

# Counts the commas ',' in a string
# 
# @param string [String] The string to be counted
# @return [Integer] the amount of commas in string
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

# Removes the earliest time and adds the time now in a string
# 
# @param timeattempts [String] the string to be iterated
# @return [Array] timeattempts and the difference between the earliest and latest time
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

# Checks if the state of the user is a admin, if it isn't it throwns an error
#
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

# Displays the Landing Page
#
get('/') do
  slim(:"planeshop/welcomepage")
end

# Displays buttons that if clicked show the Airplanes of a certain type, if logged in user also a button to show the user's bought planes, if admin also a button to create an Airplane
#
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

# Displays a create Airplane form
#
get("/planes/new") do 
  slim(:"planeshop/new")
end

# Displays the Airplanes of a type, if logged in user also a buy button under every unsold Airplane, if admin also two buttons under every Airplane for edit and delete of that Airplane
#
# @param [Integer] :typeid, the ID of the type of the Airplane
#
# @see Model#planes
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

# Creates a new Airplane and redirects to '/planes'. Also validates the params.
#
# @param [String] name, The name of the Airplane
# @param [String] description, The description of the Airplane
# @param [String] price, The price of hte Airplane
# @param [String] topspeed, The top speed of the Airplane
# @param [Integer] typeid, ID of the type of the Airplane
# @param [Integer] enginetypeid, ID of the enginetype of the Airplane
#
# @see Model#addplane
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

# Displays a edit Airplane form
#
# @see Model#selected_plane
get('/planes/:id/edit') do
  id = params[:id].to_i

  @selected_plane = selected_plane(id)

  slim(:"planeshop/edit")
end

# Updates an existing Airplane and redirects to '/planes'. Also validates the params
#
# @param [Integer] id, The id of the Airplane
# @param [String] name, The name of the Airplane
# @param [String] description, The description of the Airplane
# @param [String] price, The price of hte Airplane
# @param [String] topspeed, The top speed of the Airplane
# @param [Integer] typeid, ID of the type of the Airplane
# @param [Integer] enginetypeid, ID of the enginetype of the Airplane
#
# @see Model#update_plane
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

# Deletes an existing Airplane and redirects to '/planes'
#
# @param [Integer] :id, The ID of the Airplane
#
# @see Model#delete
post('/planes/:id/delete') do
  denna_ska_bort = params[:id].to_i

  delete(denna_ska_bort)

  redirect('/planes')
end

# Displays a register form
#
get('/register') do
  slim(:"planeshop/register")
end

# Attempts registering an account and redirects to '/login'
#
# @param [String] name, The username
# @param [String] password, The password
# @param [String] confirmpassword, The repeated password
#
# @see Model#adduser
# @see Model#idresult
# @see Model#pwd_digest
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

# Displays a login form
#
get('/login') do
  slim(:"planeshop/login")
end

# Attempts login, updates the session and redirects to 'planes'
#
# @param [String] name, The username
# @param [String] password, The password
#
# @see Model#userresult
# @see Model#updatetimeattempts
# @see Model#pwd_digest2
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

# Displays the logged in user's bought planes
#
# @param [Integer] :idcheck, The ID of the User
#
# @see Model#myplanes
get('/myplanes/:id') do
  id = session[:user_id]
  idcheck = params[:id].to_i
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

# Adds a plane to a user in the user_plane_rel table and redirects to '/planes'
#
# @param [Integer] :uid, The ID of the User
# @param [Integer] :aid, The ID of the Airplane
#
# @see Model#addplanetouser
post('/addplanetouser/:planeid') do
  uid = session[:user_id]
  aid = params[:planeid].to_i
  addplanetouser(uid,aid)
  redirect('/planes')
end

# Clears the Cache/Resets the session
#
post('/clear') do
  session.clear
  redirect('/')
end

# Displays an error message
#
get('/error') do
  slim(:"planeshop/error")
end
