module Droom
  class Scrap < ActiveRecord::Base
    belongs_to :created_by, :class_name => "Droom::User"
    belongs_to :event, :class_name => "Droom::Event"
    accepts_nested_attributes_for :event

    belongs_to :document, :class_name => "Droom::Document", :dependent => :destroy
    accepts_nested_attributes_for :document

    has_upload :image, 
               :geometry => "580x326#",
               :styles => {
                 :icon => "32x18#",
                 :thumb => "160x90#",
                 :precrop => "1200x1200^"
               }

    before_save :get_youtube_thumbnail

    scope :by_date, order("droom_scraps.created_at DESC")

    scope :later_than, lambda { |scrap| 
      where(["created_at > ?", scrap.created_at]).order("droom_scraps.created_at ASC") 
    }
    
    scope :earlier_than, lambda { |scrap| 
      where(["created_at < ?", scrap.created_at]).order("droom_scraps.created_at DESC") 
    }

    scope :matching, lambda { |fragment|
      fragment = "%#{fragment}%"
      where('droom_scraps.name LIKE :f OR droom_scraps.body LIKE :f OR droom_scraps.note LIKE :f', :f => fragment)
    }
    
    scope :visible_to, lambda { |user|
      where("1=1")
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
      # youtube id is held in the 'body' column.
      if scraptype == "video" && body?
        self.image = URI("http://img.youtube.com/vi/#{body}/0.jpg")
      end
    end
    
  end
end