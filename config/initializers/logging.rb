require 'dop_common'

if Rails.env == 'test'
  DopCommon.logger = Logger.new('/dev/null')
else
  byebug
  formatter = Rails.logger.formatter
  DopCommon.logger = Rails.logger
  Rails.logger.formatter = formatter
end
