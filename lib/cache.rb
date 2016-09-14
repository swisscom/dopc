require 'dop_common/plan_cache'
require 'dopi'

class Cache

  def self.plan_cache
    @@cache ||= DopCommon::PlanCache.new(Dopi.configuration.plan_cache_dir)
  end

  def self.set_plan_cache(dir)
    @@cache = DopCommon::PlanCache.new(dir)
  end

end
