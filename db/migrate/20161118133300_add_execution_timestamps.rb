class AddExecutionTimestamps < ActiveRecord::Migration[5.0]
  def change
    add_column :plan_executions, :started_at, :datetime
    add_column :plan_executions, :finished_at, :datetime
  end
end
