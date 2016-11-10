require 'dop_common'
require 'dopi'

logger = Rails.logger
formatter = logger.formatter
DopCommon.logger = logger
Dopi.logger = logger
Dopv.logger = logger
# Restore formatter
logger.formatter = formatter
