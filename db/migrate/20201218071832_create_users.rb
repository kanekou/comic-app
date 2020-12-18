class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string :account, unique: true
      t.string :nickname, null: false
      t.string :email, unique: true, null: false
      t.string :password, null: false
      t.string :password_solt, null: false
      t.string :profile
    end
  end
end
