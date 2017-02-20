require 'base64'
require 'yaml'
require 'tempfile'

require 'dop_common'
require 'dopi/cli/log'

class Api::V1::PlansController < Api::V1::ApiController

  def index
    plans = plan_store.list.collect{|i| {name: i}}
    render json: {plans: plans}
  end

  def show
    begin
      param_verify(key: :version, types: [String], optional: true, empty: false)
    rescue InvalidParameterError => e
      render json: {error: e.to_s}, status: :unprocessable_entity
      return
    end
    begin
      if params[:version]
        yaml = plan_store.get_plan_yaml(params[:id], params[:version])
      else
        yaml = plan_store.get_plan_yaml(params[:id])
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
      param_verify(key: :content, types: [String], empty: false)
    rescue InvalidParameterError => e
      render json: {error: e.to_s}, status: :unprocessable_entity
      return
    end
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
      name = Dopi.add(tmp.path)
    rescue StandardError => e
      render json: {error: "Failed to add plan: #{e.backtrace}"}, status: :bad_request
      return
    ensure
      tmp.unlink
    end
    render json: {name: name}, status: :created
  end

  def update_plan
    begin
      param_verify(key: :content, types: [String], optional: true, empty: false)
      param_verify(key: :plan, types: [String], optional: true, empty: false)
      param_verify(key: :clear, types: [TrueClass, FalseClass], optional: true)
      param_verify(key: :ignore, types: [TrueClass, FalseClass], optional: true)
      params_must_one([:plan, :content])
      params_only_one([:plan, :content])
    rescue InvalidParameterError => e
      render json: {error: e.to_s}, status: :unprocessable_entity
      return
    end
    name = params[:plan]
    if params[:content]
      begin
        content = Base64.decode64(params[:content])
        hash = YAML.load(content)
        plan = DopCommon::Plan.new(hash)
        name = plan.name
      rescue Exception => e
        render json: {error: "Failed to load content: #{e}"}, status: :unprocessable_entity
        return
      end
    end
    begin
      tmp = nil
      if params[:content]
        tmp = Tempfile.new('dopc')
        tmp.write(content)
        tmp.close
        unless Dopi.valid?(tmp.path)
          render json: {error: 'Plan is not valid'}, status: :unprocessable_entity
          return
        end
      end
      PlanExecution.transaction do
        if not PlanExecution.where(status: :running, plan: name).empty?
          render json: {error: "Can not update a plan that has running executions"}, status: :conflict
          return
        end
        plan_store.update(tmp.path) if params[:content]
        options = {}
        options[:clear] = true if params[:clear]
        options[:ignore] = true if params[:ignore]
        if options.empty?
          Dopi.update_state(name)
          Dopv.update_state(name)
        else
          Dopi.update_state(name, options)
          Dopv.update_state(name, options)
        end
      end
    rescue StandardError => e
      render json: {error: "Failed to update plan: #{e}"}, status: :bad_request
      return
    ensure
      tmp.unlink if tmp
    end
    render json: {name: name}
  end

  def destroy
    render json: {name: plan_store.remove(params[:id])}
  rescue StandardError => e
    render json: {error: e}, status: :not_found
  end

  def versions
    begin
      versions = plan_store.show_versions(params[:id]).collect{|i| {name: i}}
    rescue StandardError => e
      render json: {error: e}, status: :not_found
      return
    end
    render json: {versions: versions}
  end

  def reset
    begin
      param_verify(key: :force, types: [TrueClass, FalseClass], optional: true)
    rescue InvalidParameterError => e
      render json: {error: e.to_s}, status: :unprocessable_entity
      return
    end
    force = !!params[:force]
    begin
      plan_store.get_plan(params[:id])
    rescue StandardError => e
      render json: {error: "Plan not found: #{e}"}, status: :not_found
      return
    end
    Dopi.reset(params[:id], force)
    render json: {name: params[:id]}
  end

  def state
    begin
      plan_store.get_plan(params[:id])
    rescue StandardError => e
      render json: {error: "Plan not found: #{e}"}, status: :not_found
      return
    end
    render json: {state: Dopi::Cli.state(params[:id])}
  end

  private

  def plan_store
    DopCommon::PlanStore.new(DopCommon.config.plan_store_dir)
  end

end
