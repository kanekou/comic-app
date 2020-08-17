# comic-app 仕様書
気軽に漫画を投稿できるサービス

# Deploy URL
https://shrouded-castle-37624.herokuapp.com/users/hoge

## 要件定義
- ピクシブ風アプリ
- 自身が投稿した漫画を管理できる．
- 容易に創作漫画を見せられる．
- Twitterにシェアできる．

## 基本設計
### ツール
- Ruby
- sinatra
### 機能(優先順位順)
- 画像投稿
- タイトル入力
- 画像再投稿
- ログイン，プロフィール作成

- いいね
- フォロー
- コメント
- 検索
- twitter投稿機能

## ユーザーストーリー
### 訪問ユーザー
- ユーザーはSNSからリンクを踏んでやってくる
- ユーザーはページをめくることができる
- ユーザーはページ一覧を表示できる
- ユーザーはページを押すと，その漫画画像をみることができる
- ユーザーは作者の漫画一覧を表示できる
- ユーザーは，新規登録，ログインすると漫画に対してしおりを挟むことができる
- ユーザーは，その漫画に対していいねができる
- ユーザーは，作者をフォローできる
- ユーザーはフォロワーをみることができる
- ユーザーはフォロワーの漫画をみることができる
### 作者
- 作者は，漫画を新規投稿，更新ができる．新規投稿の場合，タイトルと説明を書く
- 作者は，マイページで自分のプロフィールと漫画一覧をみることができる
- 作者は，プロフィール編集ができる
- 作者は，TwitterにURLとして漫画情報を載っけられる

## Routing
### 必須
- get /  TOPページ
- get /login ログイン画面
- post /login   ログイン処理 
- get /signup  新規登録画面
- get /users/:user_account  ユーザーページ
- get /profile_edit  ユーザープロフィール編集ページ
- post /profile_edit  ユーザープロフィール更新
- get /post_comic 新規漫画投稿ページ
- post /comic 新規漫画投稿
- delete /comics/:comic_id 漫画削除
- get /comics/:user_account/:comic_id  漫画ページ一覧
- post /pages/:comic_id 漫画ページ追加
- delete /pages/:comic_id/:page_id 漫画ページ削除
- post /bookmark しおり登録

### できたら
- post /like : いいね処理
- post /follow : フォロー処理
- DELETE /like : いいね取り消し
- DELETE /follow  : フォロー取り消し
- get /like : いいね一覧
- get /following : フォロー一覧
- get /followed : フォローされてる一覧



