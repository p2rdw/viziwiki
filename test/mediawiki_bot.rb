require 'test_helper'
require 'viziwiki'
require 'viziwiki/mediawiki'

class ViziwikiTest < Minitest::Test

  def setup
    @url = 'vizitest.wiki-site.org'
    @test_prefix = 'Test:viziwiki_dev'
    @user = 'vizitest'
    @password = 'vizitestpublicpassword'
    @test_id = Viziwiki.new_uuid
    @bot = Viziwiki::Mediawiki::Bot.new
    connection = @bot.connect @url, @user, @password
    refute_nil connection
    assert_equal 0, 1
  end

  def current_test_page
    %Q{#{@test_prefix}__#{@test_id}}
  end


  def test_samples
    # this test test
    #   writing pages
    #   reading pages and parsing (aka use mediawiki api to generate html)
    for sample in 'test/sample/xxx.mediawiki'
      def get_text_files mediawiki_path
        return [.mediawiki, .mediawiki.html, .viziwiki, .viziwiki.html]
      end
      mediawiki, mediawiki_html, viziwiki, viziwiki_html = get_test_files sample

      refute_nil @bot.write page, mediawiki

      text = @bot.text page
      assert_equal mediawiki, text

      html = @bot.text_wikimedia_html page
      assert_equal mediawiki_html html

      normalized = @bot.normalize page
      assert_equal viziwiki, normalized

      @bot.normalize! page
      normalized_text = @bot.text page
      assert_equal viziwiki, normalized_text

      normalized_html = @bot.text_wikimedia_html page
      assert_equal viziwiki_html, normalized_text
    end
  end



  def test_that_it_has_a_version_number
    refute_nil ::Viziwiki::VERSION
  end
end
