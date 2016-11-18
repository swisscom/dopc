class RemoveExecutionsLog < ActiveRecord::Migration[5.0]
  def change
    remove_column :plan_executions, :log
  end
end
