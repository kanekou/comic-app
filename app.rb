require 'sinatra'
require 'sinatra/reloader'
require 'dotenv/load'
require 'pg'
require 'pry'
require 'bcrypt'

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
  # @sql = $db.exec_params("SELECT * FROM board")
  # @images = Dir.glob("./public/image/*").map{|path| path.split('/').last }
  redirect to ('/login') unless logged_in?
  erb :index
end

get '/signup' do
  erb :signup
end

post '/signup' do
  def encrypt_password(password)
    unless password.nil?
      password_solt = BCrypt::Engine.generate_salt
      password_hash = BCrypt::Engine.hash_secret(password, password_solt)
      return password_solt, password_hash
    end
  end

  nickname = params[:nickname]
  email = params[:email]
  password = params[:password]

  password_solt, password_hash =  encrypt_password(password)
  $db.exec_params('INSERT INTO users (nickname, email, password, password_solt) VALUES ($1,$2,$3,$4)', [nickname, email, password_hash, password_solt])
  session[:email] = email

  redirect to('/')
end

get '/login' do
  redirect to ('/') if logged_in?
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