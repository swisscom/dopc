ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha/test_unit'

require 'securerandom'

class ActiveSupport::TestCase

  def setup_tmp
    @tmpdir = Dir.mktmpdir
  end

  def teardown_tmp
    FileUtils.remove_entry @tmpdir
  end

  def mock_cache
    @cachedir = File.join(@tmpdir, 'cache')
    DopCommon::PlanStore.unstub(:new)
    plancache = DopCommon::PlanStore.new(@cachedir)
    DopCommon::PlanStore.stubs(:new).returns(plancache)
    Dopi.configuration.plan_store_dir = @cachedir
    Dopi.configuration.log_dir = "#{@cachedir}/log"
    Dopi.instance_variable_set('@plan_store', nil)
  end

  def mock_dopv
    Dopv.unstub(:load_data_volumes_db)
    Dopv.stubs(:load_data_volumes_db).returns(nil)
    Dopv.unstub(:run_plan)
    Dopv.stubs(:run_plan).returns(nil)
  end

  def mock_dopv_fail
    Dopv.unstub(:load_data_volumes_db)
    Dopv.stubs(:load_data_volumes_db).returns(nil)
    Dopv.unstub(:run_plan)
    Dopv.stubs(:run_plan).raises(Exception, 'Testing error')
  end

  def setup_auth
    @auth_token = SecureRandom.hex
    Api::V1::ApiController.any_instance.unstub(:get_auth_token)
    Api::V1::ApiController.any_instance.stubs(:get_auth_token).returns(@auth_token)
  end

  def auth_token
    @auth_token
  end

  def auth_header
    {'Authorization': ActionController::HttpAuthentication::Token.encode_credentials(@auth_token)}
  end

  def plan_file(name)
    Rails.root.join('test', 'fixtures', 'plans', "#{name}.yaml")
  end
  
  def read_plan(name)
    File.read(plan_file(name))
  end

  def encode_plan(name)
    Base64.encode64(read_plan(name))
  end

  def decode_plan(content)
    Base64.decode64(content)
  end

  def add_plan(name)
    cache = DopCommon::PlanStore.new(@cachedir)
    cache.add(plan_file(name))
  end

end
