require 'mediawiki_api'
require 'nokogiri'
require 'viziwiki/fact'


# bot is the object that knows about mediawiki-api and viziwiki
# to setup:
# vizibot = Viziwiki::Mediawiki::Bot.new
# vizibot.connect 'viziwiki.url.org'
connect, and then use the methods as connect
class Viziwiki::Mediawiki::Bot
  def initialize archive_path
    @wiki_url = nil
    @client = nil
    @parser = nil
    @archive_path = archive_path
  end

  # connect to the wiki via w/api.php
  def connect url, user = nil, pass = nil
    @wiki_url = "https://#{url}/w/api.php"
    @client = MediawikiApi::Client.new @wiki_url
    if @client and user and pass
      @client.log @wiki_url, user, pass
    else
      @client
    end
  end

  # get the mediawiki raw text of a page
  def text(page)
    (@client.get_wikitext page).body
  end

  # get the html version of a page rendered by wikimedia
  def text_wikimedia_html(page)
    (@client.action :parse, page: page, token_type: false).data["text"]["*"]
  end

  # write page with content and the commit_message
  def write(page, content, commit_message)
    # TODO create_page page, content
    @client.create_page page, content
  end

  #def create_page
  #  #(client.action :edit, page: page, bot: true, tags: @curren_tags, token_type: false)
  #  # bot: true
  #  # tags?
  #end

  # create new resource id
  def new_resource_id
    Viziwiki::new_uuid
    # TODO check?
  end

  # create new resource
  def create_resource id, url, hash
    # TODO
    page = resource_page id
    if is_url? url
      create_new_archive page, url, hash
    content = 'TODO'
    write page, content
  end

  # create new arxive
  def create_new_archive page, url, hbash
    archive = Viziwiki::Archiver.new self, @archive_path, page, commit_message
    @archive.archive_url url
  end

  # create new verb
  def create_verb verb
    page = verb_page verb
    content = 'TODO'
    write page, content
  end

  def create_node name
    page = node_page name
    content = 'TODO'
    write page, content
  end

  def create_role name
    page = role_page name
    content = 'TODO'
    write page, content
  end

  def create_role_node link
    #create_role
    #create_node
  end

  def create_description_node link
  end

  def create_functor_node link
  end

  def create_fact fact
  end



  def normalize(page)
    mediawiki = text page
    html = text_wikimedia_html page
    norm_mediawiki = normalize_text mediawiki, html
  end

  def normalize!(page)
    norm_mediawiki = normalize page
    write page, norm_mediawiki
    norm_mediawiki
  end

  def update_all!(page)
    # TODO
  end

  def update_since_revision!(revision_number)
    # TODO
  end

  def update_since_last_bot_edit!(botname)
    # TODO
  end

  def update_since_last_bot
    # TODO
  end

  def normalize_text(mediawiki, html)
    # TODO
    mediawiki
  end
end
