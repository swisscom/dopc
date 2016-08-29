require 'base64'
require 'yaml'
require 'dop_common/plan_cache'

class Api::V1::PlansController < Api::V1::ApiController

  def initialize
    @cache = DopCommon::PlanCache.new(Rails.configuration.cache_dir)
  end

  def index
    render json: {plans: @cache.list.collect { |plan| {name: plan}} }
  end

  def create
    hash = YAML.load(Base64.decode64(params[:content]))
    plan = @cache.add(hash)
    render json: {name: plan}
  rescue Exception => e
    render json: {error: "Failed to decode content: #{e}"}, status: :unprocessable_entity
    return
  end

  def destroy
    plan = @cache.remove(params[:id])
    render json: {name: plan}
  rescue StandardError => e
    render json: {error: e.message}, status: :not_found
  end

  def check
    plan = @cache.get(params[:id])
    valid = plan.valid?
    render json: {valid: valid}
  rescue StandardError => e
    render json: {error: e.message}, status: :not_found
  end

end
