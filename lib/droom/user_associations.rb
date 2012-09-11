module Droom
  module UserAssociations
    def self.included(base)
      base.send :has_one, :person, :class_name => "Droom::Person"
    end
    
    def events
      if person
        person.events 
      else
        []
      end
    end
  end
end
