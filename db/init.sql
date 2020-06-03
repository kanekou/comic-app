CREATE DATABASE comics_app;

\c comics_app

CREATE TABLE users (
  id SERIAL NOT NULL PRIMARY KEY ,
  account VARCHAR( 25 ) NOT NULL ,
  nickname VARCHAR( 25 ) NOT NULL ,
  email VARCHAR( 35 ) NOT NULL ,
  password VARCHAR( 60 ) NOT NULL ,
  password_solt VARCHAR NOT NULL ,
  profile VARCHAR( 150 ) ,
  UNIQUE (account)
  UNIQUE (email)
);

CREATE TABLE comics (
  id SERIAL NOT NULL PRIMARY KEY ,
  user_id int NOT NULL references users(id) ,
  title VARCHAR( 100 ) NOT NULL ,
  bio VARCHAR( 150 ),
  created_at timestamp with time zone NOT NULL,
  uploaded_at timestamp with time zone NOT NULL
);

CREATE TABLE pages (
  id SERIAL NOT NULL PRIMARY KEY ,
  comic_id int references comics(id),
  page_number int ,
  imagefile VARCHAR( 50 ),
  created_at timestamp with time zone NOT NULL,
  uploaded_at timestamp with time zone NOT NULL
);

CREATE TABLE bookmarks (
  id SERIAL NOT NULL PRIMARY KEY ,
  user_id int NOT NULL references users(id) ,
  comic_id int references comics(id),
  page_id int references pages(id),
  UNIQUE (user_id, comic_id)
);
