class Api::V1::ExecutionsController < Api::V1::ApiController

  def index
    render json: {executions: PlanExecution.all.collect { |e| {id: e.id, plan: e.plan, task: e.task, stepset: e.stepset, status: e.status, log: e[:log]}}}
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
    PlanRunner.instance.update
    render json: {id: exec.id}, status: :created
  end

  def show
    execution = PlanExecution.find(params[:id])
    if execution
      render json: execution.to_hash
    else
      render json: {error: 'Execution not found'}, status: :not_found
    end
  end

end
