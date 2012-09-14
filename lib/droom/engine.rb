module Droom
  class Engine < ::Rails::Engine
    isolate_namespace Droom
    initializer "droom.integration" do
      ActiveRecord::Base.send :include, Droom::Helpers
    end
  end
end
