module Droom
  class EventType < ActiveRecord::Base
    include Droom::Concerns::Slugged

    has_many :events, :dependent => :nullify
    has_many :folders, through: :events

    has_folder within: "Events" # here the within arguments sets the name of our parent folder

    before_validation :slug_from_name
    after_save :set_folder_confidentiality

    default_scope -> {order(:name)}

    def self.for_selection
      self.all.map {|et| [et.name, et.id]}
    end
    
    def self.default
      default_type = self.where(:slug => "other_events").first_or_initialize
      if default_type.new_record?
        default_type.name = "Other Events"
        default_type.save
      end
      default_type
    end

    def confidential?
      private?
    end

    protected

    # This is done in a very inefficient cascading sort of way in order to trigger all the right reindexings.
    # It should be a rare and special event and we prefer thorough to quick.
    #
    def set_folder_confidentiality
      folders.each {|folder| folder.set_confidentiality(private?) }
    end

  end
end