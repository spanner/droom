module Droom
  class UserActionObserver < ActiveRecord::Observer 
    observe "droom/event", "droom/document", "droom/scrap"
  
    def before_save(model)
      if model.respond_to? :created_by
        model.created_by ||= Droom::User.current
      end
    end

  end
end