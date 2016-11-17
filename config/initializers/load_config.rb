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
