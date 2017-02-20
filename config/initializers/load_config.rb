require 'yaml'

CONFIG_FILE = File.join(Rails.root, 'config', 'dopc.yml')
if File.file?(CONFIG_FILE)
  config = YAML.load_file(CONFIG_FILE)[Rails.env]
end
config ||= {}
APP_CONFIG = config

if !Rails.env.test? and !APP_CONFIG['auth_token']
  raise "Missing authentication token in configuration"
end

dop_config = DopCommon.config.config_file
if File.file?(dop_config) and !Rails.env.test?
  DopCommon.configure = YAML::load_file(dop_config)
  log.debug("Loaded DOP configuration from #{dop_config}")
end

