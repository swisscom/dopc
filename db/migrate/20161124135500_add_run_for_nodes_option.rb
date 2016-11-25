class AddRunForNodesOption < ActiveRecord::Migration[5.0]
  def change
    add_column :plan_executions, :run_for_nodes, :string
  end
end
