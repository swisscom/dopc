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
    @plan_store_dir = File.join(@tmpdir, 'plan_store')
    DopCommon::PlanStore.unstub(:new)
    plan_store = DopCommon::PlanStore.new(@plan_store_dir)
    DopCommon::PlanStore.stubs(:new).returns(plan_store)
    DopCommon.config.plan_store_dir = @plan_store_dir
    DopCommon.config.log_dir = File.join(@tmpdir, 'log')
    Dopi.instance_variable_set('@plan_store', nil)
    Dopv.instance_variable_set('@plan_store', nil)
  end

  def mock_logdir
    @logdir = File.join(@tmpdir, 'executions')
    PlanExecution.unstub(:log_dir)
    PlanExecution.stubs(:log_dir).returns(@logdir)
  end

  def mock_dopv
    Dopv.unstub(:deploy)
    Dopv.unstub(:undeploy)
    Dopv.stubs(:deploy).returns(nil)
    Dopv.stubs(:undeploy).returns(nil)
  end

  def mock_dopv_fail
    Dopv.unstub(:deploy)
    Dopv.unstub(:undeploy)
    Dopv.stubs(:deploy).raises(Exception, 'Testing error')
    Dopv.stubs(:undeploy).raises(Exception, 'Testing error')
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
    plan_store = DopCommon::PlanStore.new(@plan_store_dir)
    plan_store.add(plan_file(name))
  end

  def remove_plan(name)
    plan_store = DopCommon::PlanStore.new(@plan_store_dir)
    plan_store.remove(name)
  end

end
