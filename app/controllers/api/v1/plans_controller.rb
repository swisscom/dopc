require 'base64'
require 'yaml'
require 'dop_common'
require 'dopi'

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
      hash = YAML.load(Base64.decode64(params[:content]))
    rescue Exception => e
      render json: {error: "Failed to load content: #{e}"}, status: :unprocessable_entity
      return
    end
    begin
      name = cache.add(hash)
    rescue StandardError => e
      render json: {error: "Failed to add plan: #{e}"}, status: :bad_request
      return
    end
    render json: {name: name}, status: :created
  end

  def update_content
    begin
      hash = YAML.load(Base64.decode64(params[:content]))
    rescue Exception => e
      render json: {error: "Failed to load content: #{e}"}, status: :unprocessable_entity
      return
    end
    begin
      name = cache.update(hash)
    rescue StandardError => e
      render json: {error: "Failed to update plan: #{e}"}, status: :bad_request
      return
    end
    render json: {name: name}
  end

  def destroy
    begin
      render json: {name: cache.remove(params[:id])}
    rescue StandardError => e
      render json: {error: e}, status: :not_found
    end
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

  private

  def cache
    DopCommon::PlanStore.new(Dopi.configuration.plan_cache_dir)
  end

end
