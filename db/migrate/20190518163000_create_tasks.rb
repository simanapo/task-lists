class CreateTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :tasks do |t|
      t.integer :user_id, null: false
      t.string :task_name, limit: 1000, null: false
      t.integer :old_flg, limit: 1, null: false, default: 0
      t.timestamps null: false
    end
  end
end

