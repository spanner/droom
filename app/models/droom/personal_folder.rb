module Droom
  class PersonalFolder < ActiveRecord::Base
    belongs_to :person
    belongs_to :folder
    
    def copy_to_dropbox
      
    end
    
    def copy_to_dav
      
    end
    
    #todo: lifted from Person and awaiting translation
    #
    # def create_and_update_dav_directories
    #   document_links.each do |dl|
    #     p "-> creating DAV directory #{dl.slug}"
    #     create_dav_directory(dl.slug)
    #   end
    # end
    # 
    # def create_dav_directory(name)
    #   FileUtils.mkdir_p(Rails.root + "#{Droom.dav_root}/#{self.id}/#{name}")
    # end
    # 

    # association helpers give us more readable logic elsewhere.
    
  end
end
