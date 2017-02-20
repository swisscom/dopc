class AddRunOptionsToPlanExecutions < ActiveRecord::Migration[5.0]
  def change
    remove_column :plan_executions, :stepset
    remove_column :plan_executions, :rmdisk
    remove_column :plan_executions, :run_for_nodes
    add_column :plan_executions, :run_options, :string
  end
end
