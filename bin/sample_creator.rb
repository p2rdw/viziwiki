#!/usr/bin/env ruby

require 'bundler/setup'
require 'viziwiki'
require 'viziwiki/mediawiki'
require 'viziwiki/mediawiki/bot'


def write file, content
  File.open file, 'w' do |file|
    file.write content
  end
end


test_prefix = 'Test:viziwiki_dev_sample_creator'
url = 'localhost/w'
user = 'viziwiki_public_test_user'
pass = 'viziwiki_public_test_pass'


script_name = File.basename File.expand_path('.', __FILE__)
pp %Q{usage: #{script_name} file.mediawiki ...}
pp %Q{for each file, it generates the html mediawiki render, the normalize version, and the html mediawiki render of the normalized version}


bot = Viziwiki::Mediawiki::Bot.new
bot.connect url, user, pass

def write path, content
  File.open(path, 'w') { |f| f.write content }
end


for file in ARGV
  if File.exists? file
    test_id = ::Viziwiki.new_uuid
    content = File.read file

    # write mediawiki page
    page = %Q{#{test_prefix}__uuid-#{test_id}}
    bot.write! page, content

    # write normalized mediawiki page
    npage = %Q{#{page}__normalized}
    bot.write! npage, content
    bot.normalize! npage

    pp %Q{created pages for #{file} at #{page}}

    content = bot.text page
    ncontent = bot.text npage
    html = bot.text_wikimedia_html page
    nhtml = bot.text_wikimedia_html npage
    nncontent = bot.normalize npage

    # write outputs
    write file + '.mediawiki', content
    write file + '.mediawiki.html', html
    write file + '.norm.mediawiki', ncontent
    write file + '.norm.mediawiki.html', nhtml
    write file + '.norm.norm.mediawiki', nncontent

    pp "ERROR normalize != normalize . normalize))" if ncontent != nncontent
  else
    pp %Q{ERROR: #{file} does not exists}
  end
end
