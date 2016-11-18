module Util

  def self.rm_ensure(file)
    File.delete(file)
    return true
  # Just ignore missing file
  rescue Errno::ENOENT
    return false
  end

end
