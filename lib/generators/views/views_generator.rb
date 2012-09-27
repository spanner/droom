class ViewsGenerator < Rails::Generators::Base
  source_root File.expand_path('../../../../app/views/droom', __FILE__)
  
  def copy_views
    directory "", Rails.root + "app/views/"
  end

end

