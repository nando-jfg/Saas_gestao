class AddDetailsToUsuarios < ActiveRecord::Migration[8.1]
  def change
    add_column :usuarios, :nome, :string, null: false, default: ""
    add_column :usuarios, :papel, :integer, null: false, default: 0
    add_reference :usuarios, :empresa, null: true, foreign_key: true
  end
end
