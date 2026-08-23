class CreateEmpresas < ActiveRecord::Migration[8.1]
  def change
    create_table :empresas do |t|
      t.string :nome, null: false

      t.timestamps
    end
  end
end
