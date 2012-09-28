module Droom
  class DashboardGenerator < Rails::Generators::Base
    source_root File.expand_path('../../../../../app/views/droom', __FILE__)
  
    def copy_views
      view_directory :dashboard
    end

    protected

    def view_directory(name, _target_path = nil)
      directory name.to_s, Rails.root + "app/views/droom/#{name}"
    end

  end
end