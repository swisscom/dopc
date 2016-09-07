require 'base64'
require 'yaml'
require 'dop_common'
require 'dopi'
require 'plan_run_status'

class Api::V1::PlansController < Api::V1::ApiController

  def cache_dir
    Rails.configuration.respond_to?(:cache_dir) ? Rails.configuration.cache_dir : Dopi.configuration.plan_cache_dir
  end

  def initialize
    @cache = DopCommon::PlanCache.new(cache_dir)
  end

  def index
    render json: {plans: @cache.list.collect { |plan| {name: plan}} }
  end

  def show
    if @cache.plan_exists?(params[:id])
      plan = @cache.get(params[:id])
      hash = plan.instance_variable_get("@hash")
      content = Base64.encode64(hash.to_yaml)
      render json: {content: content}
    else
      render json: {error: 'Plan not found'}, status: :not_found
    end
  end

  def create
    hash = nil
    begin
      hash = YAML.load(Base64.decode64(params[:content]))
    rescue Exception => e
      render json: {error: "Failed to create plan from content: #{e}"}, status: :unprocessable_entity
      return
    end
    plan = DopCommon::Plan.new(hash)
    if not plan.valid?
      render json: {error: "Plan is invalid"}, status: :unprocessable_entity
      return
    end
    if @cache.plan_exists?(plan.name)
      render json: {error: "Plan already exists"}, status: :conflict
      return
    end
    render json: {name: @cache.add(hash)}, status: :created
  end

  def update
    if not @cache.plan_exists?(params[:id])
      render json: {error: "Plan does not exist"}, status: :not_found
      return
    end
    hash = nil
    begin
      hash = YAML.load(Base64.decode64(params[:content]))
    rescue Exception => e
      render json: {error: "Failed to create plan from content: #{e}"}, status: :unprocessable_entity
      return
    end
    plan = DopCommon::Plan.new(hash)
    if params[:id] != plan.name
      render json: {error: "Plan name does not match name in content"}, status: :unprocessable_entity
      return
    end
    if not plan.valid?
      render json: {error: "Plan is invalid"}, status: :unprocessable_entity
      return
    end
    @cache.update(plan.name, hash)
    render json: {name: plan.name}
  end

  def destroy
    if @cache.plan_exists?(params[:id])
      render json: {name: @cache.remove(params[:id])}
    else
      render json: {error: 'Plan not found'}, status: :not_found
    end
  end

  def check
    if @cache.plan_exists?(params[:id])
      render json: {valid: @cache.get(params[:id]).valid?}
    else
      render json: {error: 'Plan not found'}, status: :not_found
    end
  end

  def run
    if @cache.plan_exists?(params[:id])
      run = PlanRun.create(plan: params[:id], stepset: params[:stepset], status: PlanRunStatus::NEW)
      PlanRunner.instance.update(run)
      render json: {id: run.id}, status: :created
    else
      render json: {error: 'Plan not found'}, status: :not_found
    end
  end

end
