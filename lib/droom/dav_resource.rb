# To begin with this is just a directory resource chrooted to a path
# just outside the public site. Into that we push versioned document clones
# whenever a new item becomes available.
#
# This has the great advantage of detaching DAV logic from the rest of the data room.
# If people choose to add, delete or annotate files that's ok. 
#
# Later we may move to proxied S3 storage.
#
module Droom
  class DavResource < DAV4Rack::FileResource
    
    # The _DAV_ prefix is a way to evade the callback mechanism.
    # Prepare is only called by our fork of Dav4Rack, at the moment.
    # 
    def prepare
      raise Dav4Rack::Unauthorized unless person
      unless @dav_root
        @dav_root = Rails.root + "#{Droom.dav_root}/#{person.id}"
        FileUtils.mkdir_p(@dav_root) unless File.exist?(@dav_root)
      end
      if path.blank?  # any request for the root resource
        person.gather_and_update_documents
      end
    end
    
    def person
      user.person
    end

    def root
      @dav_root
    end
  
    def authenticate(email, password)
      self.user = User.find_by_email(email)
      user.try(:valid_password?, password)
    end

  end
end