class Api::V1::ExecutionsController < Api::V1::ApiController

  def index
    render json: {executions: PlanExecution.all.collect{|e| e.to_hash}}
  end

  def create
    unless params[:plan]
      render json: {error: 'Missing property: plan'}, status: :unprocessable_entity
      return
    end
    unless params[:task]
      render json: {error: 'Missing property: task'}, status: :unprocessable_entity
      return
    end
    unless PlanExecution.tasks.keys.include? params[:task]
      render json: {error: "Invalid task '#{params[:task]}', must be one of: #{PlanExecution.tasks.keys}"}, status: :unprocessable_entity
      return
    end
    exec = PlanExecution.create(plan: params[:plan], task: params[:task], stepset: params[:stepset], status: :new)
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
        render json: {error: 'Execution is already running'}, status: :conflict
        return
      end
      execution.destroy
    end
    render json: execution.to_hash
  end

  def destroy_multiple
    valid_statuses = PlanExecution.remove_statuses
    plan = params[:plan]
    statuses = params[:statuses]
    statuses.each do |s|
      unless valid_statuses.include? s
        render json: {error: "Invalid status '#{s}', must be one of: #{valid_statuses}"}, status: :unprocessable_entity
        return
      end
    end
    destroyed = nil
    PlanExecution.transaction do
      if plan
        destroyed = PlanExecution.where(plan: plan, status: statuses).destroy_all
      else
        destroyed = PlanExecution.where(status: statuses).destroy_all
      end
    end
    render json: {executions: destroyed.collect{|e| e.to_hash}}
  end

end
