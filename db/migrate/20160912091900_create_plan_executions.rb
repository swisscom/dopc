class CreatePlanExecutions < ActiveRecord::Migration[5.0]
  def change
    create_table :plan_executions do |t|
      t.string :plan, null: false
      t.integer :task, null: false
      t.string :stepset
      t.integer :status, null: false, default: 0
      t.string :log
      t.timestamps
    end
  end
end