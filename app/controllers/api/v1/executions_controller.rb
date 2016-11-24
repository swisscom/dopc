class Api::V1::ExecutionsController < Api::V1::ApiController

  def index
    render json: {executions: PlanExecution.all.collect{|e| e.to_hash}}
  end

  def create
    begin
      param_verify(key: :plan, types: [String], empty: false)
      param_verify(key: :task, types: [String], empty: false, values: PlanExecution.tasks.keys)
      param_verify(key: :stepset, types: [String], optional: true, empty: false)
      param_verify(key: :rmdisk, types: [TrueClass, FalseClass], optional: true)
      if params[:stepset]
        unless params[:task] == 'run' or params[:task] == 'setup'
          raise InvalidParameterError, 'Invalid parameters: stepset must only be used with tasks run/setup'
        end
      end
      if params[:rmdisk]
        unless params[:task] == 'undeploy'
          raise InvalidParameterError, 'Invalid parameters: rmdisk must only be used with task undeploy'
          return
        end
      end
    rescue InvalidParameterError => e
      render json: {error: e.to_s}, status: :unprocessable_entity
      return
    end
    exec = PlanExecution.create(plan: params[:plan], task: params[:task], stepset: params[:stepset], rmdisk: params[:rmdisk], status: :new)
    PlanExecution.schedule
    render json: {id: exec.id}, status: :created
  end

  def show
    execution = PlanExecution.find_by_id(params[:id])
    if execution
      render json: execution.to_hash
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
    PlanExecution.schedule
    render json: execution.to_hash
  end

  def destroy_multiple
    valid_statuses = PlanExecution.remove_statuses
    begin
      param_verify(key: :plan, types: [String], optional: true, empty: false)
      param_verify_list(key: :statuses, types: [String], values: valid_statuses, empty_values: false)
    rescue InvalidParameterError => e
      render json: {error: e.to_s}, status: :unprocessable_entity
      return
    end
    plan = params[:plan]
    statuses = params[:statuses]
    destroyed = nil
    PlanExecution.transaction do
      if plan
        destroyed = PlanExecution.where(plan: plan, status: statuses).destroy_all
      else
        destroyed = PlanExecution.where(status: statuses).destroy_all
      end
    end
    destroyed.each do |e|
      e.delete_log
    end
    PlanExecution.schedule
    render json: {executions: destroyed.collect{|e| e.to_hash}}
  end

  def log
    execution = PlanExecution.find_by_id(params[:id])
    if execution
      render json: {log: execution.read_log}
    else
      render json: {error: 'Execution not found'}, status: :not_found
    end
  end

end
