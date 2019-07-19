require 'nokogiri'
require 'viziwiki/fact'
require 'viziwiki/utils'
require 'viziwiki/mediawiki/api'
require 'viziwiki/mediawiki/parser'



# bot is the object that knows about mediawiki-api and viziwiki
# to initiazlie:
# vizibot = Viziwiki::Mediawiki::Bot.new
# vizibot.connect 'viziwiki.url.org' [, 'user', 'pass']


class Viziwiki::Mediawiki::Bot

  def self.default_local
    url = 'localhost/w'
    user = 'viziwiki_public_test_user'
    pass = 'viziwiki_public_test_pass'
    bot = Viziwiki::Mediawiki::Bot.new
    bot.connect url, user, pass
    bot
  end


  # archive_path where it is stored the archive files
  #     if arcguve_path is nil, archive features is disable
  # upload_archive whether the bot should try to upload .tar.gz to the wiki
  def initialize archive_path = nil, upload_archive = false
    @wiki_url = nil
    @client = nil
    @archive_path = archive_path
    @upload_archive = upload_archive
  end


  # connect to the wiki via w/api.php
  def connect url, user = nil, pass = nil
    # WARNING do not use rewritten urls never ever...
    # url should be the base url so url/index.php url/api.php should be there
    @wiki_url = "http://#{url}/api.php"
    @client = Viziwiki::Mediawiki::API.new @wiki_url
    @client.log_in user, pass if @client and user and pass
  end


  # get the mediawiki raw text of a page
  def text page
    @client.text page
  end


  # get the html version of a page rendered by wikimedia
  def text_wikimedia_html page
    html = @client.text_wikimedia_html page
    # normalize html by removing <!-- html comments -->
    doc = Nokogiri.HTML html
    (doc.xpath '//comment()').remove
    doc.inner_html
  end



  # write page with content and the commit_message
  def write! page, content, message = nil
    unless message
      message = %Q{bot edit with empty message}
    end
    @client.write! page, content, message
  end


  # TODO remove this methods, it was for debug pruposes
  def client
    @client
  end


  # create new resource id
  def new_resource_id!
    uuid = Viziwiki::new_uuid
    # TODO write lock with create only
    #do
    #  uuid = Viziwiki::new_uuid
    #unless lock_resource (uuid)
    uuid
  end



  # normalize a page
  def normalize_text mediawiki, html, page
    parser = Viziwiki::Mediawiki::Parser.new self
    if parser.parse mediawiki, html, page
      parser.normalized_text
    else
      raise TypeError, "wiki page: #{page} cannot be parsed"
      nil
    end
  end


  # normalize a page
  def normalize page
    mediawiki = text page
    html = text_wikimedia_html page
    normalize_text mediawiki, html, page
  end


  # normalize and edit the page with the normalization (if it wasn-t already normalized)
  def normalize! page
    mediawiki = text page
    html = text_wikimedia_html page
    norm_mediawiki = normalize_text mediawiki, html, page
    if mediawiki != norm_mediawiki
      write! page, norm_mediawiki
    else
      pp %Q{normalize! page #{page} already normalized}
    end
    norm_mediawiki
  end


  # normalize all pages
  def update_all!
    page = nil
    while (pages = @client.next_pages page).size > 0
      for current_page in pages
        page = current_page['title']
        normalize! page
        # TODO
        #   normalize
        #   get context
        #   updated_facts
        #   arxive stuff
        #   etc...
      end
    end
  end




  def lock_or_fail_page! page, content, message
    client.lock_or_fail_page! page, content, message
  end


  def lock_or_fail! obj
    if obj.class == ::Viziwiki::Fact
      lock_or_fail_page! *lock_fact_page(obj)
    else
      raise TypeError, "Unexpected object for lock_or_fail #{obj.class} #{obj}"
    end
  end


  # TODO refactor templates into
  # => mediawiki/lock_templates                     # page templates for the locks
  # => mediawiki/page_templates                     # page templates
  # => mediawiki/viziwiki_pages/last_robot_updates  # special page model
  def lock_fact_page fact
    page = fact.name
    message = "This is page has been created automatically for locking resource pruposes."
    tags = %w(
      LOCK
      TODO
      TODOBO
      fact
      fact-ed
    )
    content = %Q{
This is the page of the fact [[#{fact.name}]]

 #{message}

#{Viziwiki::Utils.header "fact-ed message"}
[[This]] [[~is]] [[the page]][[.of]] the fact [[.#{fact.name}]].

#{Viziwiki::Utils.tag_section tags}
}
    [page, content, message]
  end



  def fact_seq fact_name, fact
    # TODO
    true
  end










  # TODO ALL
  # create new resource
  def create_resource id, url, hash
    # TODO
    page = resource_page id
    if is_url? url
      create_new_archive page, url, hash
    end
    content = 'TODO'
    write! page, content
  end


  # create new arxive
  def create_new_archive page, url, hbash, base_dir
    archieve_comment = %Q{created new archive from page: #{page}, url: #{url}}
    archive = Viziwiki::Archiver.new self, @archive_path, page, archieve_comment
    if upload_archive
      tar_gz = basedir # TODO
      archive.archive_url_and_upload url, tar_gz
    else
      archive.archive_url url
    end
  end


  # create new verb
  def create_verb verb
    page = verb_page verb
    content = 'TODO'
    write! page, content
  end

  def verb_page verb
    verb
  end


  def create_node name
    # TODO
    page = node_page name
    content = 'TODO'
    write! page, content
  end

  def node_page name
    name
  end


  def create_role name
    page = role_page name
    content = 'TODO'
    write! page, content
  end

  def role_page role
    role
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





end
