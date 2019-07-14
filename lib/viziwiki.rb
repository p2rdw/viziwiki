require 'viziwiki/version'
require 'securerandom'

module Viziwiki
  def new_uuid
    SecureRandom.uuid
  end
end
