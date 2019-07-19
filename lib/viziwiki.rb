require 'viziwiki/version'
require 'securerandom'
require 'logger'


module Viziwiki

  # uuid stuff
  def self.new_uuid
    SecureRandom.uuid
  end


  # logging stuff
  @@logger = Logger.new(STDERR)

  def self.set_log_output path
    @@logger = Logger.new(path)
  end

  def self.set_log_level level
    @@logger.level = level
  end

  def self.log
     @@logger
     # [lambda { |req| __method__ }]
     # caller.first
     # maybe overwrite? debug and so with info about caller.first?
     #    .source_location...
  end

end
