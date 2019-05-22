require 'sinatra'
require 'sinatra/reloader'
require 'dotenv/load'
require 'pg'
require 'pry'

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
  nickname = params[:nickname]
  email = params[:email]
  password = params[:password]

  $db.exec_params('INSERT INTO users (nickname, email, password) VALUES ($1,$2,$3)', [nickname, email, password])
  session[:email] = email

  redirect to('/')
end

get '/login' do
  redirect to ('/') if logged_in?
  erb :login
end

post '/login' do
  email = params[:email]
  password = params[:password]

  users = $db.exec_params('select * from users where email = $1 and password = $2', [email, password]).first
  session[:email] = email unless users.nil?

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