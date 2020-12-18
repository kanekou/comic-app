class CreateComics < ActiveRecord::Migration[6.1]
  def change
    create_table :comics do |t|
      t.references :user, foreign_key: true, null: false
      t.string :title, null: false
      t.string :bio

      t.timestamps
    end
  end
end
