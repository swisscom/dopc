class AddRmdiskOption < ActiveRecord::Migration[5.0]
  def change
    add_column :plan_executions, :rmdisk, :boolean
  end
end
