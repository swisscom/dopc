class Api::V1::ExecutionsController < Api::V1::ApiController

  def index
    render json: PlanExecution.all
  end

  def create
    plan_execution = PlanExecution.new(plan_execution_params)
    if plan_execution.save
      ExecutePlanJob.perform_later(plan_execution)
      render json: plan_execution, status: :created
    else
      render json: {error: plan_execution.errors}, status: :unprocessable_entity
    end
  end

  def show
    execution = PlanExecution.find_by_id(params[:id])
    if execution
      render json: execution
    else
      render json: {error: 'Execution not found'}, status: :not_found
    end
  end

  def destroy
    execution = nil
    PlanExecution.transaction do
      execution = PlanExecution.find_by_id(params[:id])
      unless execution
        render json: {error: 'Execution not found'}, status: :not_found
        return
      end
      if execution.status_running?
        render json: {error: 'Can not remove a running execution'}, status: :conflict
        return
      end
      execution.destroy
    end
    execution.delete_log
    render json: execution
  end

  def destroy_multiple
    valid_statuses = PlanExecution.remove_statuses
    begin
      param_verify(key: :plan, types: [String], optional: true, empty: false)
      param_verify_list(key: :statuses, types: [String], values: valid_statuses, empty_values: false)
      param_verify(key: :age, types: [Fixnum], optional: true)
    rescue InvalidParameterError => e
      render json: {error: e.to_s}, status: :unprocessable_entity
      return
    end
    destroyed = nil
    PlanExecution.transaction do
      select = PlanExecution.where(status: params[:statuses])
      select = select.where(plan: params[:plan]) if params[:plan]
      select = select.where('created_at < ?', Time.now - params[:age]) if params[:age]
      destroyed = select.destroy_all
    end
    destroyed.each do |e|
      e.delete_log
    end
    render json: destroyed
  end

  def log
    execution = PlanExecution.find_by_id(params[:id])
    if execution
      render json: {log: execution.read_log}
    else
      render json: {error: 'Execution not found'}, status: :not_found
    end
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def plan_execution_params
    params.permit(
      :plan,
      :task,
      :run_options => [
        :step_set,
        :noop,
        :rmdisk,
        :run_for_nodes => {},
      ],
    )
  end

end
