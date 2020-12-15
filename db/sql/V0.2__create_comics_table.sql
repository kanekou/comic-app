CREATE TABLE comics (
  id SERIAL NOT NULL PRIMARY KEY ,
  user_id int NOT NULL references users(id) ,
  title VARCHAR( 100 ) NOT NULL ,
  bio VARCHAR( 150 ),
  created_at timestamp with time zone NOT NULL,
  updated_at timestamp with time zone NOT NULL
);

