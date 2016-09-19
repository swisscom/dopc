ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha/test_unit'

class ActiveSupport::TestCase

  def setup_tmp
    @tmpdir = Dir.mktmpdir
  end

  def teardown_tmp
    FileUtils.remove_entry @tmpdir
  end

  def mock_cache
    @cachedir = File.join(@tmpdir, 'cache')
    DopCommon::PlanCache.unstub(:new)
    plancache = DopCommon::PlanCache.new(@cachedir)
    DopCommon::PlanCache.stubs(:new).returns(plancache)
    Dopi.configuration.plan_cache_dir = @cachedir
  end

  def mock_dopv
    Dopv.unstub(:load_data_volumes_db)
    Dopv.stubs(:load_data_volumes_db).returns(nil)
    Dopv.unstub(:run_plan)
    Dopv.stubs(:run_plan).returns(nil)
  end

  def mock_dopv_fail
    Dopv.unstub(:run_plan)
    Dopv.stubs(:run_plan).raises(Exception, 'Testing error')
  end

  def mock_dopi
    Dopi.unstub(:run_plan)
    Dopi.stubs(:run_plan).returns(nil)
  end

  def mock_dopi_fail
    Dopi.unstub(:run_plan)
    Dopi.stubs(:run_plan).raises(Exception, 'Testing error')
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
    YAML.load(Base64.decode64(content))
  end

  def add_plan(name)
    cache = DopCommon::PlanCache.new(Dopi.configuration.plan_cache_dir)
    cache.add(plan_file(name))
  end

end
