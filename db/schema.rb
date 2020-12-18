# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_12_18_075518) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bookmarks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "comic_id", null: false
    t.bigint "page_id"
    t.index ["comic_id"], name: "index_bookmarks_on_comic_id"
    t.index ["page_id"], name: "index_bookmarks_on_page_id"
    t.index ["user_id", "comic_id"], name: "index_bookmarks_on_user_id_and_comic_id"
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "comics", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.string "bio"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_comics_on_user_id"
  end

  create_table "pages", force: :cascade do |t|
    t.bigint "comic_id", null: false
    t.integer "page_number", null: false
    t.text "imagefile"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["comic_id"], name: "index_pages_on_comic_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "account"
    t.string "nickname", null: false
    t.string "email", null: false
    t.string "password", null: false
    t.string "password_solt", null: false
    t.string "profile"
  end

  add_foreign_key "bookmarks", "comics"
  add_foreign_key "bookmarks", "pages"
  add_foreign_key "bookmarks", "users"
  add_foreign_key "comics", "users"
  add_foreign_key "pages", "comics"
end
