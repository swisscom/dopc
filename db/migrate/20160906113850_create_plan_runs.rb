class CreatePlanRuns < ActiveRecord::Migration[5.0]
  def change
    create_table :plan_runs do |t|
      t.string :plan, null: false
      t.string :stepset
      t.integer :status, null: false
      t.string :log
      t.timestamps
    end
  end
end
