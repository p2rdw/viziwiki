require "test_helper"
require 'viziwiki'


class ViziwikiTest < ViziwikiTestBase
  def test_that_it_has_a_version_number
    version = ::Viziwiki::VERSION
    refute_nil version
  end


  def test_new_uuid
    new_uuid = ::Viziwiki.new_uuid
    log.info %Q{test_new_uuid: #{new_uuid}}
    refute_nil ::Viziwiki.new_uuid
  end
end
