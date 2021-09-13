class AddNameToAccount < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :name, :string, default: '名無し'
  end
end
