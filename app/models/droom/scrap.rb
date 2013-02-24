module Droom
  class Scrap < ActiveRecord::Base
    belongs_to :created_by, :class_name => "Droom::User"
    has_upload :image, 
               :geometry => "580x326#",
               :styles => {
                 :icon => "32x18#",
                 :thumb => "160x90#",
                 :precrop => "1200x1200^"
               }

    searchable do
      text :name, :boost => 10, :stored => true
      text :body, :stored => true
      text :note
    end

    def self.highlight_fields
      [:name, :body]
    end

    attr_accessible :name, :body, :image, :description, :scraptype, :note, :created_by
    before_save :get_youtube_thumbnail

    scope :by_date, order("droom_scraps.created_at DESC")

    scope :later_than, lambda { |scrap| 
      where(["created_at > ?", scrap.created_at]).order("droom_scraps.created_at ASC") 
    }
    
    scope :earlier_than, lambda { |scrap| 
      where(["created_at < ?", scrap.created_at]).order("droom_scraps.created_at DESC") 
    }

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
        ((560.0/(1.4 * l+150.0)) + 0.25) / 1.5
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

    def as_search_result
      {
        :type => 'scrap',
        :prompt => name,
        :value => name,
        :id => id
      }
    end
    
    def next_younger
      Droom::Scrap.later_than(self).first
    end
    
    def next_older
      Droom::Scrap.earlier_than(self).first
    end

  protected
  
    def get_youtube_thumbnail
      # youtube id is held in the 'note' column.
      if scraptype == "video" && body?
        self.image = URI.parse("http://img.youtube.com/vi/#{body}/0.jpg")
      end
    end
    
  end
end