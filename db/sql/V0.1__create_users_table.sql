CREATE TABLE users (
  id SERIAL NOT NULL PRIMARY KEY ,
  account VARCHAR( 25 ) NOT NULL ,
  nickname VARCHAR( 25 ) NOT NULL ,
  email VARCHAR( 35 ) NOT NULL ,
  password VARCHAR( 60 ) NOT NULL ,
  password_solt VARCHAR NOT NULL ,
  profile VARCHAR( 150 ) ,
  UNIQUE (account),
  UNIQUE (email)
);

