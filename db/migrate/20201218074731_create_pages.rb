class CreatePages < ActiveRecord::Migration[6.1]
  def change
    create_table :pages do |t|
      t.references :comic, foreign_key: true, null: false
      t.integer :page_number, null: false
      t.text :imagefile

      t.timestamps
    end
  end
end
