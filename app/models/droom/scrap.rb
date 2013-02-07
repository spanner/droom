module Droom
  class Scrap < ActiveRecord::Base
    belongs_to :created_by, :class_name => "Droom::User"
    has_upload :image, 
               :geometry => "720x720#",
               :styles => {
                 :icon => "32x32#",
                 :thumb => "120x120#",
                 :precrop => "1600x1600^"
               }

    attr_accessible :name, :body, :image, :description, :scraptype, :note, :created_by
    before_save :get_youtube_thumbnail
    default_scope order("droom_scraps.created_at desc")
    
    Droom.scrap_types.each do |t|
      define_method(:"#{t}?") { type == t.to_s }
      scope t.pluralize.to_sym, where(["type == ?", t])
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
  
  protected
  
    def get_youtube_thumbnail
      # youtube id is held in the 'note' column.
      if scraptype == "video" && note?
        self.image = URI.parse("http://img.youtube.com/vi/#{note}/0.jpg")
      end
    end
  
  end
end