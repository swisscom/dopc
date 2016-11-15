module Log

  def self.set_loggers(logger, keep_formatter = false)
    formatter = logger.formatter if keep_formatter
    DopCommon.logger = logger
    Dopi.logger = logger
    Dopv.logger = logger
    logger.formatter = formatter if keep_formatter
  end

end
