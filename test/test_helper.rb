$LOAD_PATH.unshift File.expand_path("../lib", __dir__)


require 'minitest/autorun'
require "viziwiki"
require 'logger'




class ViziwikiTestBase < Minitest::Test
  def setup
    @log = Logger.new STDERR
    ::Viziwiki.set_log_output STDERR
    ::Viziwiki.set_log_level Logger::DEBUG
  end


  def log
    ::Viziwiki.log
  end


  def basedir
    File.expand_path(".", __dir__)
  end


  def test_basedir
    path = basedir
    log.info %Q{test_basedir: #{path}}
    refute_nil path
  end


  def current_test_page
    %Q{#{@test_prefix}__uuid-#{@test_id}}
  end
end
