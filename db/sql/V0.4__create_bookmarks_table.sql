CREATE TABLE bookmarks (
  id SERIAL NOT NULL PRIMARY KEY ,
  user_id int NOT NULL references users(id) ,
  comic_id int references comics(id),
  page_id int references pages(id),
  UNIQUE (user_id, comic_id)
);
