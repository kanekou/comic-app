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

  def find_comic(comic_id)
    $db.exec_params('select * from comics where id = $1', [comic_id]).first
  end

  def find_user_by_account(user_account)
    $db.exec_params('select * from users where account = $1', [user_account]).first
  end
end

get '/' do
  redirect to ("users/#{current_user['account']}") if logged_in?
  erb :index
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

get "/users/:user_account" do
  # redirect to ('/') unless logged_in?
  @user = find_user_by_account(params[:user_account])
  erb :mypage
end

get "/users/:user_account/edit" do
  @user = find_user_by_account(params[:user_account])
  erb :mypage_edit
end

post "/users/:user_account/edit" do
  user = $db.exec_params('select * from users where email = $1', [session[:email]]).first
  redirect to ('/') unless current_user?(user)

  $db.exec_params('update users set nickname = $1, profile = $2 where id = $3', [params[:nickname], params[:profile], user['id']])
  redirect to ("/users/#{current_user['account']}")
end

get '/comics/:user_account/:comic_id' do
  @user = find_user_by_account(params[:user_account])
  @comic = find_comic(params[:comic_id])
  @pages = $db.exec_params('select * from pages where comic_id = $1', [params[:comic_id]])

  erb :comic
end

post '/pages/:comic_id' do
  # 画像の保存
  filename = "#{current_user['id']}_#{params[:comic_id]}_#{params[:page_number]}"
  current_file_path = params[:file][:tempfile]
  file_type = params[:file][:type].split('/').last
  move_file_path = "/image/#{filename}.#{file_type}"

  FileUtils.mv(current_file_path, "./public/#{move_file_path}")

  #db保存
  $db.exec_params('INSERT INTO pages (comic_id, page_number, imagefile, created_at, uploaded_at) VALUES ($1,$2,$3,$4,$5)', [params[:comic_id], params[:page_number], move_file_path, Time.now, Time.now])
  redirect to ("/comics/#{current_user['account']}/#{params[:comic_id]}")
end

post '/comics/:comic_id' do
  $db.exec_params('INSERT INTO comics (user_id, title, bio, created_at, uploaded_at) VALUES ($1,$2,$3,$4,$5)', [current_user['id'], params[:title], params[:bio], Time.now, Time.now])
  redirect to ("/comics/#{current_user['account']}/#{params[:comic_id]}")
end

delete '/comics/:comic_id' do
  $db.exec_params('delete from comics where id = $3', [params[:comic_id]])
  redirect to ("/users/#{current_user['account']}")
end

post '/upload' do
  # @filename = params[:file][:filename]
  comic = $db.exec_params('select * from comic where id = $1', [comic_id]).first
  pages = params[:file][:filename]
  @filename = "#{current_user['id']}_#{comic['id']}_#{page['id']}"
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