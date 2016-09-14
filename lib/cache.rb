require 'dop_common/plan_cache'
require 'dopi'

class Cache

  def self.plan_cache
    @@cache ||= DopCommon::PlanCache.new(Dopi.configuration.plan_cache_dir)
  end

  def self.plan_cache=(plan_cache)
    @@cache = plan_cache
  end

end
