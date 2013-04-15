module Droom
  class Engine < ::Rails::Engine
    isolate_namespace Droom
    initializer "droom.integration" do
      ActiveRecord::Base.send :include, Droom::ModelHelpers
      ActiveRecord::Base.send :include, Droom::Taggability
      ActiveRecord::Base.send :include, Droom::Folders
      ActiveSupport.on_load :action_controller do
        helper Droom::DroomHelper
      end
    end

    config.to_prepare do
      # Base layout. Uses app/views/layouts/my_layout.html.erb
      Doorkeeper::ApplicationController.layout Droom.layout
    end

  end
end
