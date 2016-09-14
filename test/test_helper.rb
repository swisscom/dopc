ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'cache'

class ActiveSupport::TestCase

  def setup_tmpcache
    @cachedir = Dir.mktmpdir
    Cache.set_plan_cache(@cachedir)
  end
  
  def teardown_tmpcache
    FileUtils.remove_entry @cachedir
  end

  def read_plan(name)
    File.read(Rails.root.join('test', 'fixtures', 'plans', "#{name}.yaml"))
  end

  def encode_plan(name)
    Base64.encode64(read_plan(name))
  end

  def decode_plan(content)
    YAML.load(Base64.decode64(content))
  end

  def add_plan(name)
    post '/api/v1/plans', params: {content: encode_plan(name)}, as: :json
    data = JSON.parse(@response.body)
    assert_response :created
    assert_equal name, data['name']
  end
  
end
