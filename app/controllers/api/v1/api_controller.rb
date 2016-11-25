class Api::V1::ApiController < ActionController::API

  include ActionController::MimeResponds
  include ActionController::HttpAuthentication::Token::ControllerMethods 

  wrap_parameters false

  before_action :accept_json, :json_content, :authenticate

  private

  def accept_json
    respond_to :json
  rescue ActionController::UnknownFormat
    render json: {error: 'Client does not accept JSON format'}, status: :not_acceptable
  end

  def json_content
    if request.content_type && (request.content_type != 'application/json')
      render json: {error: 'Client set content type to non-JSON format'}, status: :unsupported_media_type
    end
  end

  def authenticate
    authenticate_or_request_with_http_token do |token, options|
      token == get_auth_token
    end
  end

  def get_auth_token
    APP_CONFIG['auth_token']
  end

  def param_verify(key:, name: nil, types: nil, values: nil, optional: false, empty: nil)
    name = key.to_s unless name
    if params[key]
      if types and not types.include?(params[key].class)
        raise InvalidParameterError, "Wrong parameter type: type of '#{name}' must be one of '#{types}'"
      end
      if empty != nil and !empty and params[key].empty?
        raise InvalidParameterError, "Parameter '#{name}' must not be empty"
      end
      if values and not values.include?(params[key])
        raise InvalidParameterError, "Invalid parameter value: '#{name}' must be one of '#{values}'"
      end
    else
      unless optional
        raise InvalidParameterError, "Missing parameter: '#{name}'"
      end
    end
  end

  def param_verify_list(key:, name: nil, types: nil, values: nil, optional: false, empty_list: false, empty_values: nil)
    name = key.to_s unless name
    if params[key]
      unless params[key].is_a?(Array)
        raise InvalidParameterError, "Invalid parameter type: '#{name}' must be an array"
      end
      if not empty_list and params[key].empty?
        raise InvalidParameterError "Parameter '#{name}' must not be empty"
      end
      params[key].each do |val|
        if types and not types.include?(val.class)
          raise InvalidParameterError, "Invalid parameter type: type of values in '#{name}' must be one of '#{types}'" 
        end
        if empty_values != nil and !empty_values and val.empty?
          raise InvalidParameterError, "Values in parameter '#{name}' must not be empty"
        end
        if values and not values.include?(val)
          raise InvalidParameterError, "Invalid parameter value: values in '#{name}' must be one of '#{values}'"
        end
      end
    else
      unless optional
        raise InvalidParameterError, "Missing parameter: '#{name}'"
      end
    end
  end

  def params_must_one(names)
    ok = false
    names.each do |n|
      ok = true if params[n]
    end
    unless ok
      raise InvalidParameterError, "Missing parameter: must specify one of '#{names}'"
    end
  end

  def params_only_one(names)
    count = 1
    names.each do |n|
      count -= 1 if params[n]
    end
    if count < 0
      raise InvalidParameterError, "Too much parameters: must not specify more than one of '#{names}'"
    end
  end

end

class InvalidParameterError < StandardError
end
