module Droom
  class Engine < ::Rails::Engine
    isolate_namespace Droom
    initializer "droom.integration" do
      User.send :include, Droom::UserAssociations
      ActiveRecord::Base.send :include, Droom::Helpers
    end
  end
end
