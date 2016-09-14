require 'test_helper'

class ExecutionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    setup_tmpcache
  end

  teardown do
    teardown_tmpcache
  end

end
