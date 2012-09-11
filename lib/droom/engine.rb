module Droom
  class Engine < ::Rails::Engine
    isolate_namespace Droom
    initializer "droom.integration" do
      User.send(:include, Droom::UserAssociations)
    end
  end
end
