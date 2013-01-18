module Droom
  module Folders
  
    def self.included(base)
      base.extend FolderClassMethods
    end

    module FolderClassMethods
      def has_folder?
        false
      end
      
      def has_folder
        return if has_folder?
        has_one :folder, :as => :holder
        has_many :documents, :through => :folder

        class_eval {
          extend Droom::Folders::FolderedClassMethods
          include Droom::Folders::FolderedInstanceMethods
        }
      end
    end

    module FolderedClassMethods
      def has_folder?
        true
      end
    end
  
    module FolderedInstanceMethods
      def lazy_load_folder
        folder || self.create_folder
      end
      
      def add_document(params)
        lazy_load_folder.documents.create(params)
      end
    end
  end

end