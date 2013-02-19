module Droom
  class Scrap < ActiveRecord::Base
    belongs_to :created_by, :class_name => "Droom::User"
    has_upload :image, 
               :geometry => "580x435#",
               :styles => {
                 :icon => "32x32#",
                 :thumb => "160x120#",
                 :precrop => "1200x1200^"
               }

    attr_accessible :name, :body, :image, :description, :scraptype, :note, :created_by
    before_save :get_youtube_thumbnail
    default_scope order("droom_scraps.created_at desc")
    
    Droom.scrap_types.each do |t|
      define_method(:"#{t}?") { scraptype == t.to_s }
      scope t.pluralize.to_sym, where(["scraptype == ?", t])
    end

    def wordiness
      if body.length < 48
        'word'
      elsif body.length < 320
        'phrase'
      elsif body.length < 800
        'paragraph'
      else
        'text'
      end
    end
  
    def text_size
      if l = body.length
        ((600.0/(l+100.0)) + 0.25) / 1.5
      else
        1
      end
    end
    
    def url_with_protocol
      body =~ /^https?:\/\// ? body : "http://#{body}"
    end

    def url_without_protocol
      body.sub(/^https?:\/\//, '')
    end
    
  protected
  
    def get_youtube_thumbnail
      # youtube id is held in the 'note' column.
      if scraptype == "video" && note?
        self.image = URI.parse("http://img.youtube.com/vi/#{note}/0.jpg")
      end
    end
    
  end
end