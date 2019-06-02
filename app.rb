require 'sinatra'
require 'sinatra/reloader'
require 'dotenv/load'
require 'pg'
require 'pry'
require 'bcrypt'
require 'rack/flash'

use Rack::MethodOverride
enable :sessions
use Rack::Flash

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

  def find_last_page_number(comic_id)
    last_page_number = $db.exec_params('SELECT * FROM pages WHERE comic_id = $1 ORDER BY page_number DESC LIMIT 1', [comic_id]).first['page_number']
    return 0 if last_page_number.nil?
    return last_page_number.to_i
  end

  def find_page_number(page_id)
    $db.exec_params('SELECT page_number FROM pages WHERE id = $1',[page_id]).first['page_number']
  end

  # flash情報のリセット
  def reset_flashes
    flash[:danger] = nil
    flash[:notice] = nil
  end

  require "uri"
  def text_url_to_link text
    URI.extract(text, ['https']).uniq.each do |url|
      sub_text = ""
      sub_text << "<a href=" << url << " target=\"_blank\">" << url << "</a>"
      text.gsub!(url, sub_text)
    end
    return text
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

  reset_flashes
  account = params[:account]
  nickname = params[:nickname]
  email = params[:email]
  password = params[:password]
  password_confirm = params[:password_confirm]
  profile = params[:profile]

  unless password == password_confirm #再入力passが異なる場合
    flash[:danger] = 'パスワードが異なります'
    redirect to ('/')
  end

  password_solt, password_hash =  encrypt_password(password)
  $db.exec_params('INSERT INTO users (account, nickname, email, password, password_solt, profile) VALUES ($1,$2,$3,$4,$5,$6)',
    [account, nickname, email, password_hash, password_solt, profile])
  session[:email] = email

  flash[:notice] = '登録しました'
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

  reset_flashes
  email = params[:email]
  password = params[:password]

  session[:email] = email if user_authenticate(email, password)

  if session[:email].nil?
    flash[:danger] = 'メールアドレスまたはパスワードが異なります'
    redirect to ('/login')
  end

  flash[:notice] = 'ログインしました'
  redirect to ('/')
end

post '/logout' do
  reset_flashes
  session[:email] = nil
  flash[:notice] = 'ログアウトしました'
  redirect to ('/login')
end

get "/users/:user_account" do
  @user = find_user_by_account(params[:user_account])
  @comics = $db.exec_params('SELECT * FROM comics WHERE user_id = $1', [@user['id']])
  erb :mypage
end

get "/profile_edit" do
  unless logged_in?
    reset_flashes
    flash[:danger] = 'ログインしていません'
    redirect to ('/login')
  end

  erb :mypage_edit
end

post "/profile_edit" do
  reset_flashes
  user = $db.exec_params('SELECT * FROM users WHERE email = $1', [session[:email]]).first
  profile = params[:profile].gsub(/\r\n|\r|\n/, "<br />") # 改行に対する処理

  $db.exec_params('UPDATE users SET nickname = $1, profile = $2 WHERE id = $3', [params[:nickname], profile, user['id']])
  flash[:notice] = 'プロフィール情報を更新しました'
  redirect to ("/users/#{current_user['account']}")
end

get '/comics/:user_account/:comic_id' do
  @user = find_user_by_account(params[:user_account])
  @comic = find_comic(params[:comic_id])
  pages = $db.exec_params('SELECT * FROM pages WHERE comic_id = $1', [params[:comic_id]])
  @pages = pages.sort_by { |page| page["page_number"] } #表示順番を整える．

  @bookmark = $db.exec_params('SELECT * FROM bookmarks WHERE user_id = $1 AND comic_id = $2', [current_user['id'], params[:comic_id]]).first

  if @bookmark.nil?
    @bookmark_page_number = 1
  else
    @bookmark_page_number = $db.exec_params('SELECT * FROM pages WHERE id = $1 AND comic_id = $2', [@bookmark['page_id'], @bookmark['comic_id']]).first['page_number'].to_i
  end

  erb :comic
end

# 漫画投稿ページ
get '/post_comic' do
  unless logged_in?
    reset_flashes
    flash[:danger] = 'ログインしていません'
    redirect to ('/login')
  end

  erb :post_comic
end

# 新規漫画投稿
post '/comic' do
  reset_flashes
  # comicデータの保存
  bio = params[:bio].gsub(/\r\n|\r|\n/, "<br />") # 改行に対する処理
  $db.exec_params('INSERT INTO comics (user_id, title, bio, created_at, updated_at) VALUES ($1,$2,$3,$4,$5)', [current_user['id'], params[:title], bio, Time.now, Time.now])
  comic = $db.exec_params('SELECT * FROM comics ORDER BY id DESC LIMIT 1').first

  # page画像データの保存
  page_params = []
  page_params.push(params[:page1],params[:page2],params[:page3],params[:page4])

  page_params.each_with_index do |page_param, index|
    page_name = "#{current_user['id']}_#{comic['id']}_#{index+1}"
    next if page_param.nil?
    current_file_path = page_param[:tempfile]
    file_type = page_param[:type].split('/').last
    move_file_path = "/image/#{page_name}.#{file_type}"
    FileUtils.mv(current_file_path, "./public/#{move_file_path}")

    $db.exec_params('INSERT INTO pages (comic_id, page_number, imagefile, created_at, updated_at) VALUES ($1,$2,$3,$4,$5)', [comic['id'], index+1, move_file_path, Time.now, Time.now])

    # comicの更新日時を更新
    $db.exec_params('UPDATE comics SET updated_at = $1 WHERE id = $2', [Time.now, comic['id']]) if index == 3
  end

  flash[:notice] = '投稿しました'
  redirect to ("/comics/#{current_user['account']}/#{comic['id']}")
end

# comic編集ページ
get '/comics_edit/:user_account/:comic_id' do
  @user = find_user_by_account(params[:user_account])
  @comic = find_comic(params[:comic_id])

  unless current_user?(@user)
    reset_flashes
    flash[:danger] = '編集権限がありません'
    redirect to ('/login')
  end

  erb :comic_edit
end

# comic編集
post '/comics/:comic_id' do
  reset_flashes
  bio = params[:bio].gsub(/\r\n|\r|\n/, "<br />") # 改行に対する処理
  $db.exec_params('UPDATE comics SET title = $1, bio = $2, updated_at = $3 WHERE id = $4', [params[:title], bio, Time.now, params[:comic_id]])
  flash[:notice] = '編集しました'
  redirect to ("/comics/#{current_user['account']}/#{params[:comic_id]}")
end

# comic削除
delete '/comics/:comic_id' do
  reset_flashes
  $db.exec_params('DELETE FROM pages WHERE comic_id = $1', [params[:comic_id]])
  $db.exec_params('DELETE FROM comics WHERE id = $1', [params[:comic_id]])

  flash[:notice] = 'コミック削除しました'
  redirect to ("/users/#{current_user['account']}")
end

# page追加
post '/pages/:comic_id' do
  reset_flashes
  # 画像の保存
  filename = "#{current_user['id']}_#{params[:comic_id]}_#{params[:page_number]}"
  current_file_path = params[:file][:tempfile]
  file_type = params[:file][:type].split('/').last
  move_file_path = "/image/#{filename}.#{file_type}"
  FileUtils.rm("./public/#{move_file_path}") if FileTest.exists?("./public/#{move_file_path}")   # 同じファイルが存在したら元の画像を削除する．
  FileUtils.mv(current_file_path, "./public/#{move_file_path}")

  #db保存
  $db.exec_params('INSERT INTO pages (comic_id, page_number, imagefile, created_at, updated_at) VALUES ($1,$2,$3,$4,$5)', [params[:comic_id], params[:page_number], move_file_path, Time.now, Time.now])
  $db.exec_params('UPDATE comics SET updated_at = $1 WHERE id = $2', [Time.now, params[:comic_id]])

  flash[:notice] = 'ページを追加しました'
  redirect to ("/comics/#{current_user['account']}/#{params[:comic_id]}")
end

# page削除
delete '/page/:comic_id/:page_id' do
  reset_flashes
  $db.exec_params('DELETE FROM pages WHERE id = $1', [params[:page_id]])
  flash[:notice] = 'ページ削除しました'
  redirect to ("comics/#{current_user['account']}/#{params['comic_id']}")
end

post '/bookmark' do
  reset_flashes

  # Bookmarkしたページが消されたor存在しない場合
  if $db.exec_params('SELECT id FROM pages WHERE comic_id = $1 AND page_number = $2', [params[:comic_id], params[:page_number]]).first.nil?
    flash[:danger] = "対象のページが存在しません"
    redirect to ("/comics/#{current_user['account']}/#{params[:comic_id]}")
  end

  page_id = $db.exec_params('SELECT id FROM pages WHERE comic_id = $1 AND page_number = $2', [params[:comic_id], params[:page_number]]).first['id']

  # userが対象comicに対してしおりをつけたことがある場合
  unless $db.exec_params('SELECT id FROM bookmarks WHERE user_id = $1 AND comic_id = $2', [current_user['id'], params[:comic_id]]).first.nil?
    $db.exec_params('UPDATE bookmarks SET page_id = $1 WHERE user_id = $2 AND comic_id = $3', [page_id, current_user['id'], params[:comic_id]])
  else # userがしおりをつけたことがないか，対象comicに対してしおりをつけたことがない場合
    $db.exec_params('INSERT INTO bookmarks (user_id, comic_id, page_id) VALUES($1, $2, $3)', [current_user['id'], params[:comic_id], page_id])
  end

  flash[:notice] = "#{params[:page_number]}ページ目にしおりを挟みました"
  redirect to ("/comics/#{current_user['account']}/#{params[:comic_id]}")
end