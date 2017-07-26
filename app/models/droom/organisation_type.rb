module Droom
  class OrganisationType < ActiveRecord::Base
    has_many :organisations
    
    has_folder within: "Organisations" # here the within arguments sets the name of our parent folder

    before_validation :slug_from_name
    default_scope -> {order(:name)}
  
    def self.for_selection
      self.all.map {|et| [et.name, et.id]}
    end
    
    def self.default
      default_type = self.where(:slug => "other_organisations").first_or_initialize
      if default_type.new_record?
        default_type.name = "Other Organisations"
        default_type.save
      end
      default_type
    end

    def confidential?
      private?
    end
    
  end
  end
end