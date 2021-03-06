module Droom
  class Scrap < ActiveRecord::Base
    belongs_to :created_by, :class_name => "Droom::User"

    belongs_to :event, :class_name => "Droom::Event", :dependent => :destroy
    accepts_nested_attributes_for :event
    belongs_to :document, :class_name => "Droom::Document", :dependent => :destroy
    accepts_nested_attributes_for :document

    has_attached_file :image,
                      :styles => {
                        :notice => "960x",
                        :icon => "32x32#",
                        :thumb => "130x73#"
                      }
    do_not_validate_attachment_file_type :image

    before_save :get_youtube_thumbnail
    before_validation :name_associates

    scope :by_date, -> { order("droom_scraps.created_at DESC") }

    scope :latest, -> limit { order("droom_scraps.created_at DESC").limit(limit) }

    scope :later_than, -> scrap { where(["created_at > ?", scrap.created_at]).order("droom_scraps.created_at ASC")  }

    scope :earlier_than, -> scrap { where(["created_at < ?", scrap.created_at]).order("droom_scraps.created_at DESC")  }

    scope :matching, -> fragment {
      fragment = "%#{fragment}%"
      where('droom_scraps.name LIKE :f OR droom_scraps.body LIKE :f OR droom_scraps.note LIKE :f', :f => fragment)
    }
    
    scope :visible_to, -> user { where("1=1") }
    
    scope :with_future_or_current_event, -> {
      joins(:event)
        .where(["droom_scraps.scraptype = 'event' AND (droom_events.finish > :now) OR (droom_events.finish IS NULL AND droom_events.start > :now)", :now => Time.zone.now])
        .order('droom_events.start ASC')
    }

    Droom.scrap_types.each do |t|
      scope t.pluralize.to_sym, -> { where(:scraptype => t.to_s) }
    end

    default_scope -> { includes(:event, :document) }

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
      if body?
        body =~ /^https?:\/\// ? body : "http://#{body}"
      end
    end

    def url_without_protocol
      body.sub(/^https?:\/\//, '') if body?
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
      if scraptype == "video" && youtube_id?
        self.image = URI("http://img.youtube.com/vi/#{youtube_id}/0.jpg")
      end
    end
    
    def name_associates
      event.name = name if event
      document.name = name if document
    end
    
  end
end