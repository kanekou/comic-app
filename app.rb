require 'sinatra'
require 'sinatra/reloader'
require 'dotenv/load'
require 'pg'
require 'pry'
require 'bcrypt'
# require 'Datatime'

use Rack::MethodOverride
enable :sessions

$db = PG::connect(
  :host => "localhost",
  :user => 'e165726', :password => '',
  :dbname => "comics_app"
  )

helpers do
  # 現在ログイン中のユーザーを返す (いる場合)
  def current_user
    return unless session[:email]
    $db.exec_params('select * from users where email = $1', [session[:email]]).first
  end

  # 渡されたユーザーがログイン済みユーザーであればtrueを返す
  def current_user?(user)
    user == current_user
  end

  # ユーザーがログインしていればtrue、その他ならfalseを返す
  def logged_in?
    !current_user.nil?
  end
end

get '/' do
  redirect to ("users/#{current_user['account']}") if logged_in?
  erb :index
end

get "/users/:user_account" do
  # redirect to ('/') unless logged_in?
  @user = $db.exec_params('select * from users where account = $1', [params[:user_account]]).first
  erb :mypage
end

get "/users/:user_account/edit" do
  @user = $db.exec_params('select * from users where account = $1', [params[:user_account]]).first
  erb :mypage_edit
end

post "/users/:user_account/edit" do
  user = $db.exec_params('select * from users where email = $1', [session[:email]]).first
  redirect to ('/') unless current_user?(user)

  $db.exec_params('update users set nickname = $1, profile = $2 where id = $3', [params[:nickname], params[:profile], user['id']])
  redirect to ("/users/#{current_user['account']}")
end

post '/signup' do
  def encrypt_password(password)
    unless password.nil?
      password_solt = BCrypt::Engine.generate_salt
      password_hash = BCrypt::Engine.hash_secret(password, password_solt)
      return password_solt, password_hash
    end
  end

  account = params[:account]
  nickname = params[:nickname]
  email = params[:email]
  password = params[:password]
  password_confirm = params[:password_confirm]
  profile = params[:profile]

  redirect to ('/') unless password == password_confirm #再入力passが異なる場合

  password_solt, password_hash =  encrypt_password(password)
  $db.exec_params('INSERT INTO users (account, nickname, email, password, password_solt, profile) VALUES ($1,$2,$3,$4,$5,$6)',
    [account, nickname, email, password_hash, password_solt, profile])
  session[:email] = email

  redirect to ("/users/#{current_user['account']}")
end

get '/login' do
  redirect to ("users/#{current_user['account']}") if logged_in?
	erb :login
end

post '/login' do
  def user_authenticate(email, password)
    user = $db.exec_params('select * from users where email = $1', [email]).first
    if user && user['password'] == BCrypt::Engine.hash_secret(password, user['password_solt'])
      true
    else
      false
    end
  end

  email = params[:email]
  password = params[:password]

  session[:email] = email if user_authenticate(email, password)

  redirect to ('/login') if session[:email].nil?
  redirect to ('/')
end

get '/logout' do
  redirect to ('/login') unless logged_in?
  erb :logout
end

post '/logout' do
  session[:email] = nil
  redirect to ('/login')
end



post '/upload' do
  # @filename = params[:file][:filename]
  commic = $db.exec_params('select * from comic where id = $1', [commic_id]).first
  pages = params[:file][:filename]
  @filename = "#{current_user['name']}_#{commic['id']}_#{page['id']}"
  # binding.pry
  file_path = params[:file][:tempfile]

  FileUtils.mv(file_path, "./public/image/#{@filename}")

  redirect to ('/')
#   > params
# => {"file"=>
#   {"filename"=>"mac_wallpaper_2560x1600_00578.jpg",
#    "type"=>"image/jpeg",
#    "name"=>"file",
#    "tempfile"=>
#     #<File:/var/folders/kc/zpyq1l3x62qghqc9m5v3s8vw0000gn/T/RackMultipart20190523-15367-11iezit.jpg>,
#    "head"=>
#     "Content-Disposition: form-data; name=\"file\"; filename=\"mac_wallpaper_2560x1600_00578.jpg\"\r\nContent-Type: image/jpeg\r\n"}}
end