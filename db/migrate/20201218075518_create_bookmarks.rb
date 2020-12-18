class CreateBookmarks < ActiveRecord::Migration[6.1]
  def change
    create_table :bookmarks do |t|
      t.references :user, foreign_key: true, null: false
      t.references :comic, foreign_key: true, null: false
      t.references :page, foreign_key: true
    end

    add_index :bookmarks, %i[user_id comic_id]
  end
end
