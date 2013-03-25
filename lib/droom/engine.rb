module Droom
  class Engine < ::Rails::Engine
    isolate_namespace Droom
    initializer "droom.integration" do
      ActiveRecord::Base.send :include, Droom::ModelHelpers
      ActiveRecord::Base.send :include, Droom::Taggability
      ActiveRecord::Base.send :include, Droom::Folders
    end
    
    initializer 'droom.action_controller' do |app|
      ActiveSupport.on_load :action_controller do
        helper Droom::DroomHelper
      end
    end
    
    
  end
end
