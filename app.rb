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
    $db.exec_params('SELECT * FROM users WHERE email = $1', [session[:email]]).first
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
    $db.exec_params('SELECT * FROM comics WHERE id = $1', [comic_id]).first
  end

  def find_user_by_account(user_account)
    $db.exec_params('SELECT * FROM users WHERE account = $1', [user_account]).first
  end

  def find_title_page(comic_id)
    page_title = $db.exec_params('SELECT * FROM pages WHERE comic_id = $1 ORDER BY page_number ASC LIMIT 1', [comic_id]).first
    return nil if page_title.nil?
    return page_title['imagefile']
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
  erb :login, :layout => :layout
end

post '/login' do
  def user_authenticate(email, password)
    user = $db.exec_params('SELECT * FROM users WHERE email = $1', [email]).first
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

# get '/logout' do
#   redirect to ('/login') unless logged_in?
#   erb :layout
# end

post '/logout' do
  session[:email] = nil
  redirect to ('/login')
end

get "/users/:user_account" do
  @user = find_user_by_account(params[:user_account])
  @comics = $db.exec_params('SELECT * FROM comics WHERE user_id = $1', [@user['id']])
  erb :mypage
end

get "/users/:user_account/edit" do
  @user = find_user_by_account(params[:user_account])
  erb :mypage_edit
end

post "/users/:user_account/edit" do
  user = $db.exec_params('SELECT * FROM users WHERE email = $1', [session[:email]]).first
  redirect to ('/') unless current_user?(user)

  $db.exec_params('UPDATE users SET nickname = $1, profile = $2 WHERE id = $3', [params[:nickname], params[:profile], user['id']])
  redirect to ("/users/#{current_user['account']}")
end

get '/comics/:user_account/:comic_id' do
  @user = find_user_by_account(params[:user_account])
  @comic = find_comic(params[:comic_id])
  @pages = $db.exec_params('SELECT * FROM pages WHERE comic_id = $1', [params[:comic_id]])

  erb :comic
end

# 漫画投稿ページ
get '/post_comic' do
  redirect to ('/') unless logged_in?
  erb :post_comic
end

# 新規漫画投稿
post '/comic' do
  # comicデータの保存
  $db.exec_params('INSERT INTO comics (user_id, title, bio, created_at, updated_at) VALUES ($1,$2,$3,$4,$5)', [current_user['id'], params[:title], params[:bio], Time.now, Time.now])
  comic = $db.exec_params('SELECT * FROM comics ORDER BY id DESC LIMIT 1').first

  # page画像データの保存
  page_params = []
  page_params.push(params[:page1],params[:page2],params[:page3],params[:page4])

  page_params.each_with_index do |page_param, index|
    page_name = "#{current_user['id']}_#{comic['id']}_#{index+1}"

    if page_param.nil?
      move_file_path = ""
    else
      current_file_path = page_param[:tempfile]
      file_type = page_param[:type].split('/').last
      move_file_path = "/image/#{page_name}.#{file_type}"
      FileUtils.mv(current_file_path, "./public/#{move_file_path}")
    end

    $db.exec_params('INSERT INTO pages (comic_id, page_number, imagefile, created_at, updated_at) VALUES ($1,$2,$3,$4,$5)', [comic['id'], index+1, move_file_path, Time.now, Time.now])

    # comicの更新日時を更新
    $db.exec_params('UPDATE comics SET updated_at = $1 WHERE id = $2', [Time.now, comic['id']]) if index == 3
  end

  redirect to ("/comics/#{current_user['account']}/#{comic['id']}")
end

# comic削除
delete '/comics/:comic_id' do
  $db.exec_params('DELETE FROM pages WHERE comic_id = $1', [params[:comic_id]])
  $db.exec_params('DELETE FROM comics WHERE id = $1', [params[:comic_id]])

  redirect to ("/users/#{current_user['account']}")
end

# page追加
post '/pages/:comic_id' do
  # 画像の保存
  filename = "#{current_user['id']}_#{params[:comic_id]}_#{params[:page_number]}"
  current_file_path = params[:file][:tempfile]
  file_type = params[:file][:type].split('/').last
  move_file_path = "/image/#{filename}.#{file_type}"

  FileUtils.mv(current_file_path, "./public/#{move_file_path}")

  #db保存
  $db.exec_params('INSERT INTO pages (comic_id, page_number, imagefile, created_at, updated_at) VALUES ($1,$2,$3,$4,$5)', [params[:comic_id], params[:page_number], move_file_path, Time.now, Time.now])
  $db.exec_params('UPDATE comics SET updated_at = $1 WHERE id = $2', [Time.now, params[:comic_id]])
  redirect to ("/comics/#{current_user['account']}/#{params[:comic_id]}")
end

# page削除
delete '/page/:comic_id/:page_id' do
  $db.exec_params('DELETE FROM pages WHERE id = $1', [params[:page_id]])
  redirect to ("comics/#{current_user['account']}/#{params['comic_id']}")
end