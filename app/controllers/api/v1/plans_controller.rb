require 'base64'
require 'yaml'
require 'dop_common'

class Api::V1::PlansController < Api::V1::ApiController

  def initialize
    @cache = DopCommon::PlanCache.new(Rails.configuration.cache_dir)
  end

  def index
    render json: {plans: @cache.list.collect { |plan| {name: plan}} }
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
    render json: {name: @cache.add(hash)}
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

end
