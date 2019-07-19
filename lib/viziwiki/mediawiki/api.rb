require 'mediawiki_api'


class Viziwiki::Mediawiki::API < ::MediawikiApi::Client
  # max item per call
  CLIENT_LIMIT = 500


  # get the mediawiki raw text of a page
  def text page
    (get_wikitext page).body
  end


  # get the html version of a page rendered by wikimedia
  def text_wikimedia_html page
    (action :parse, page: page, token_type: false).data["text"]["*"]
  end


  def write! page, content, message = nil
    message = api_context + message
    token = get_csrf_token
    (action :edit, title: page, text: content, summary: message, bot: true, token: token).data
  end


  def lock_or_fail_page! page, content, message
    message = api_context + message # get the current logic stack
    token = get_csrf_token
    begin
      action :edit, createonly: true, title: page, text: content, summary: message, bot: true, token: token
      true
    rescue => e
      # because createonly MediawikiApi::ApiError is raise if page already exists
      false
    end
  end


  # from_page   is a node name, page name, wikimedia page title
  #             if nil, it retrieves from the first page
  # return a list of wiki pages
  def next_pages from_page = nil
    if from_page
      pages = action :query, list: 'allpages', apfrom: from_page, aplimit: CLIENT_LIMIT, token_type: false
      pages.data['allpages'][1..-1]
    else
      pages = action :query, list: 'allpages', aplimit: CLIENT_LIMIT, token_type: false
      pages.data['allpages']
    end
  end


  # get token from wikimedia api
  def get_csrf_token
    (action :query, meta: 'tokens', type: 'csrf').data
  end


  # return wikimedia_api client for debug pruposes...
  def wikimedia_api_client
    self
  end


  # write api context
  def api_context
    %Q{api_context> TODO}
  end
end
