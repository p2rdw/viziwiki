require 'test_helper'
require 'viziwiki'
require 'viziwiki/mediawiki'
require 'viziwiki/mediawiki/bot'


class ViziwikiTest < ViziwikiTestBase


  def setup
    @test_id = ::Viziwiki.new_uuid
    @bot = Viziwiki::Mediawiki::Bot.default_local
    @test_prefix = 'Test:viziwiki_dev_test'
    refute_nil @bot
  end

  def bot
    @bot
  end


  def current_test_page
    %Q{#{@test_prefix}__uuid-#{@test_id}}
  end


  def test_samples
    samples_path = File.join basedir, 'mediawiki_samples', '*', '/*.sample'
    Dir.glob(samples_path) do |path|
      log.info "test_sample path: #{path}"

      basename  = File.basename path, '.sample'
      dirname   = File.dirname path
      path      = File.join dirname, basename

      pp path
      page_wiki = path      + '.mediawiki'
      page_html = page_wiki + '.html'
      norm_wiki = path      + '.norm.mediawiki'
      pp norm_wiki
      norm_html = norm_wiki + '.html'

      log.info %{test_samples #{File.basename page_wiki}}

      assert (File.exists? page_wiki), "expected test file not found #{page_wiki}"
      assert (File.exists? page_html), "expected test file not found #{page_html}"
      assert (File.exists? norm_wiki), "expected test file not found #{norm_wiki}"
      assert (File.exists? norm_html), "expected test file not found #{norm_html}"

      pw = File.read page_wiki
      ph = File.read page_html
      nw = File.read norm_wiki
      nh = File.read norm_html

      refute_nil pw
      refute_nil ph
      refute_nil nw
      refute_nil nh

      page = current_test_page
      bot.write! page, pw, "test_sample: #{path}"
      p_w = bot.text page
      p_h = bot.text_wikimedia_html page
      bot.normalize! page
      n_w = bot.text page
      n_h = bot.text_wikimedia_html page
      bot.normalize! page
      nn_w = bot.text page
      nn_h = bot.text_wikimedia_html page

      pp p_w
      pp n_w
      pp nn_w

      assert_equal pw, p_w,   "page != write . text page"
      assert_equal_but_fact nw, n_w,   "npage != normalize! . write . text page"
      assert_equal n_w, nn_w, "looks like normalize is not idempotent"

      # but fact...
      assert_equal ph, p_h
      assert_equal_but_fact nh, n_h
      assert_equal n_h, nn_h, "looks like normalize is not idempotent"
    end
  end

  def assert_equal_but_fact a, b, message = nil
    as = a.split /Fact-[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}/  # TODO refacor
    bs = b.split /Fact-[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}/  # TODO refactor
    assert_equal as, bs, message
  end
end
