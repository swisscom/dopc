class Api::V1::ExecutionsController < Api::V1::ApiController

  def index
    render json: {executions: PlanExecution.all.collect { |e| {id: e.id, plan: e.plan, dopi: e.dopi, dopv: e.dopv, stepset: e.stepset, status: e.status, log: e.log}}}
  end

  def create
    unless params[:plan]
      render json: {error: 'Missing property: plan'}, status: :unprocessable_entity
      return
    end
    unless params[:dopi]
      render json: {error: 'Missing property: dopi'}, status: :unprocessable_entity
      return
    end
    unless params[:dopv]
      render json: {error: 'Missing property: dopv'}, status: :unprocessable_entity
      return
    end
    unless params[:dopi] or params[:dopv]
      render json: {error: 'Either dopi or dopv must be set'}, status: :unprocessable_entity
      return
    end
    exec = PlanExecution.create(plan: params[:plan], dopi: params[:dopi], dopv: params[:dopv], stepset: params[:stepset], status: :new)
    PlanExecutor.instance.update
    render json: {id: exec.id}, status: :created
  end

end
