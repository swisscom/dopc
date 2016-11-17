require 'base64'
require 'yaml'
require 'tempfile'

require 'dop_common'
require 'dopi/cli/log'

class Api::V1::PlansController < Api::V1::ApiController

  def index
    plans = cache.list.collect{|i| {name: i}}
    render json: {plans: plans}
  end

  def show
    begin
      if params[:version]
        yaml = cache.get_plan_yaml(params[:id], params[:version])
      else
        yaml = cache.get_plan_yaml(params[:id])
      end
    rescue StandardError => e
      render json: {error: e}, status: :not_found
      return
    end
    content = Base64.encode64(yaml)
    render json: {content: content}
  end

  def create
    begin
      content = Base64.decode64(params[:content])
      hash = YAML.load(content)
    rescue Exception => e
      render json: {error: "Failed to load content: #{e}"}, status: :unprocessable_entity
      return
    end
    tmp = Tempfile.new('dopc')
    begin
      tmp.write(content)
      tmp.close
      name = Dopi.add(tmp)
    rescue StandardError => e
      render json: {error: "Failed to add plan: #{e}"}, status: :bad_request
      return
    ensure
      tmp.unlink
    end
    render json: {name: name}, status: :created
  end

  def update_content
    begin
      content = Base64.decode64(params[:content])
      hash = YAML.load(content)
      plan = DopCommon::Plan.new(hash)
    rescue Exception => e
      render json: {error: "Failed to load content: #{e}"}, status: :unprocessable_entity
      return
    end
    tmp = Tempfile.new('dopc')
    begin
      PlanExecution.transaction do
        if not PlanExecution.where(status: :running, plan: plan.name).empty?
          render json: {error: "Can not update a plan that has running executions"}, status: :conflict
        end
        tmp.write(content)
        tmp.close
        Dopi.update_plan(tmp, {:clear => true})
      end
    rescue StandardError => e
      render json: {error: "Failed to update plan: #{e}"}, status: :bad_request
      return
    ensure
      tmp.unlink
    end
    render json: {name: plan.name}
  end

  def destroy
    render json: {name: cache.remove(params[:id])}
  rescue StandardError => e
    render json: {error: e}, status: :not_found
  end

  def versions
    begin
      versions = cache.show_versions(params[:id]).collect{|i| {name: i}}
    rescue StandardError => e
      render json: {error: e}, status: :not_found
      return
    end
    render json: {versions: versions}
  end

  def reset
    unless params[:force].is_a?(TrueClass) or params[:force].is_a?(FalseClass)
      render json: {error: "Force must be true/false"}, status: :unprocessable_entity
      return
    end
    begin
      cache.get_plan(params[:id])
    rescue StandardError => e
      render json: {error: "Plan not found: #{e}"}, status: :not_found
      return
    end
    Dopi.reset(params[:id], params[:force])
    render json: {name: params[:id]}
  end

  def state
    begin
      cache.get_plan(params[:id])
    rescue StandardError => e
      render json: {error: "Plan not found: #{e}"}, status: :not_found
      return
    end
    render json: {state: Dopi::Cli.state(params[:id])}
  end

  private

  def cache
    DopCommon::PlanStore.new(Dopi.configuration.plan_store_dir)
  end

end
