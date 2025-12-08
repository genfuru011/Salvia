class CreateProjects < ActiveRecord::Migration[7.0]
  def change
    create_table :projects do |t|
      t.string :name
      t.string :status # active, completed, on_hold
      t.integer :budget
      t.integer :spent
      t.date :start_date
      t.date :due_date
      t.timestamps
    end
  end
end
