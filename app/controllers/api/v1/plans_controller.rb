require 'base64'
require 'yaml'
require 'dop_common/plan_cache'

class Api::V1::PlansController < Api::V1::ApiController

  def initialize
    # TODO: make path configurable
    @cache = DopCommon::PlanCache.new('cache')
  end

  def index
    render json: {plans: @cache.list.collect { |plan| {name: plan}} }
  end

  def create
    begin
      hash = YAML.load(Base64.decode64(params[:content]))
    rescue Exception => e
      render json: {error: "Failed to decode content: #{e}"}, status: :unprocessable_entity
      return
    end
    begin
      plan = @cache.add(hash)
      render json: {name: plan}
    rescue StandardError => e
      render json: {error: e.message}, status: :conflict
    end
  end

  def destroy
    plan = @cache.remove(params[:id])
    render json: {name: plan}
  rescue StandardError => e
    render json: {error: e.message}, status: :not_found
  end

end
