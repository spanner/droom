module Droom
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    
    def copy_initializer_file
      copy_file "droom_initializer.rb", Rails.root + "config/initializers/droom.rb"
    end
    
    def rake_db
      rake("db:migrate")
    end
    
  end
end