module Droom
  class Engine < ::Rails::Engine
    isolate_namespace Droom
    initializer "droom.integration" do
      ActiveRecord::Base.send :include, Droom::Helpers
      ActiveRecord::Base.send :include, Droom::Taggability
      ActiveRecord::Base.send :include, Droom::Folders
      ActiveRecord::Base.send :include, Droom::Preferences
    end
  end
end
