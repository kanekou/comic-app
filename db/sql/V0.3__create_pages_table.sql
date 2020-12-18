CREATE TABLE pages (
  id SERIAL NOT NULL PRIMARY KEY ,
  comic_id int references comics(id),
  page_number int ,
  imagefile text,
  created_at timestamp with time zone NOT NULL,
  updated_at timestamp with time zone NOT NULL
);
