# This is the mechanism by which any droom entity can declare that it has a document folder.
# The has_folder declaration brings in all the necessary document association machinery and 
# hides the folder-management machinery behind document addition and removal methods.
#
# 

module Droom
  module Folders
  
    def self.included(base)
      base.extend FolderClassMethods
    end

    module FolderClassMethods
      def has_folder?
        false
      end
      
      def has_folder( options={} )
        return if has_folder?

        has_one :folder, :as => :holder, :class_name => "Droom::Folder"
        has_many :documents, :through => :folder, :class_name => "Droom::Document"
        after_save :update_folder
        
        # This will be an association name. If set, our folder will be created as a child of that folder.
        class_variable_set(:"@@parent_folder_holder", options[:within])
        
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
      def get_parent_folder
        if pfh = self.class.class_variable_get(:"@@parent_folder_holder")
          if holder = send(pfh.to_sym)
            holder.lazy_load_folder
          end
        end
      end
      
      def add_document(attributes)
        documents.create(attributes)
      end

      def receive_document(doc)
        documents << doc
      end
      
      def update_folder
        self.folder ||= self.create_folder(:parent => get_parent_folder)
      end
      
    end
  end

end