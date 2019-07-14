# resources
# create resource/uuid/Info.md

# use wget, curl or https://jhawthorn.github.io/curl-to-ruby/

class Viziwiki::Archiver
  LEVEL=3
  BACKUP=8
  TRIES=16
  WAIT=8
  MAX_REDIRECT=16

  def initialize bot, base_dir, page, commit_message
    @bot = bot
    @base_dir = base_dir
    @page = page
    @commit_message = commit_message
    @current_date =  Time.now
  end

  def normalize_url url
    url
  end

  def directory_url url
    %Q{#{@base_dir}.#{Viziwiki::render_date current_date}}
  end

  def archive_url url
    url = normalize_url url
    resource_id = @bot.new_resource_id
    message = @bot.archieve_url_todo? url
    path = Path.join(base_dir, 'resource', resource_id)
    system %Q{mkdir #{path}}
    system %Q{cd #{path}}
    system %Q{mkdir youtube #{path}}
    system %Q{mkdir mirror #{path}}
    y = youtube url
    m = mirror_url url
    write_listing_file url

    resource = @bot.new_resource resource_id, url, archieve_url_todo: message, youtube_json: y, mirror_json: m

    @bot.new_resource url, archieve_url_todo: message, youtube: is_youtube
  end

  def write_listing_file
     # TODO write this into the listing file.
     nil
   end

  def youtube url
    spawn %Q{cd youtube; youtube-dl --all-sub --embed-subs #{url}}
  end

  def mirror_url resource_id, url
    dir = directory_url url
    spawn %Q{cd mirror ; wget
  --recursive
  --no-clobber
  --page-requisites
  --no-remove-listing
  --backups=#{BACKUP}
  --level=#{LEVEL}
  --force-directories
  --tries=#{TRIES}
  --random-wait
  --wait=#{WAIT}
  --ignore-length
  --max-redirect=#{MAX_REDIRECT}
  --user
  --password
    #{url}
}
  end
end
