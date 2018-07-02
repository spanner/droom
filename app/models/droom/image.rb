require "open-uri"

module Droom
  class Image < ApplicationRecord
    belongs_to :user
    belongs_to :organisation
    attr_accessor :remote_url

    has_attached_file :file,
                      default_url: nil,
                      preserve_files: true,
                      styles: {
                        hero: ["1600x1600>", :jpg],
                        full: "960x640#",
                        half: "480x320#",
                        icon: ["96x64#", :png]
                      },
                      convert_options: {
                        hero: "-quality 25 -strip",
                        full: "-quality 50 -strip",
                        half: "-quality 50 -strip",
                        icon: "-strip"
                      }

    validates_attachment_content_type :file, :content_type => /\Aimage/
    before_validation :get_organisation
    before_validation :read_remote_url
    after_post_process :read_dimensions

    def url(style=:original, decache=true)
      if file?
        url = file.url(style, decache)
        url.sub(/^\//, "#{Settings.protocol}://#{Settings.host}/")
      else
        ""
      end
    end

    def file_url=(address)
      if address.present?
        begin
          self.file = URI(address)
        rescue OpenURI::HTTPError => e
          Rails.logger.warn "Cannot read image url #{address} because: #{e}. Skipping."
        end
      end
    end

    def file_name=(name)
      self.file_file_name = name
    end

    def file_data=(data)
      self.file = data
    end

    protected
    
    # *read_dimensions* is called after post processing to record in the database the original width, height and
    # extension of the uploaded file. At this point the file should still be in the write queue so we can have a look at it.
    #
    def read_dimensions
      if uploaded_image = file.queued_for_write[:original]
        file = uploaded_image.send :destination
        geometry = Paperclip::Geometry.from_file(file)
        self.width = geometry.width
        self.height = geometry.height
      end
      true
    end

    def get_organisation
      self.organisation ||= user.organisation if user
    end

    def read_remote_url
      if remote_url
        self.file = open(remote_url)
        self.file_name = File.basename(remote_url)
      end
    end

  end
end
