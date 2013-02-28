# Documents in droom are never attached directly to an object. Instead they are always attached to a folder,
# and the folder is usually attached to an object. The folder itself is a normal ActiveRecord object with a 
# name and some tree behaviours that allow us to present a filing system.
#
# This file defines the interface by which we declare that an object has a folder and would like to receive documents.
# 
# It is also possible to have a loose folder: in that case it is considered public and available to everyone.
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

      # In most cases all you need is a `has_folder` line in the model class definition.
      #
      #   class Thing < ActiveRecord::Base
      #     has_folder
      #   end
      #
      # This will bring in the folder and document associations and all the instance methods
      # involved in adding and removing documents. The folder itself is lazy-loaded: the first
      # time it is requested, it will be created.
      #
      # You can specify that the folder should be created inside another folder. For example, the
      # document folder associated with an agenda_category is always created within the folder of
      # its event, so that the filing system reflects the organisation of the event. To achieve this,
      # pass in the name of an associate as the `:within` option:
      #
      #   class Subthing < ActiveRecord::Base
      #     belongs_to :thing
      #     has_folder :within => :thing
      #   end
      #
      def has_folder( options={} )
        return if has_folder?
        has_one :folder, :as => :holder, :class_name => "Droom::Folder"
        has_many :documents, :through => :folder, :class_name => "Droom::Document"
        # The :within option is stored as a class variable that will be consulted when the folder is created.
        class_variable_set(:"@@parent_folder_holder", options[:within])
        
        class_eval {
          extend Droom::Folders::FolderedClassMethods
          include Droom::Folders::FolderedInstanceMethods
          alias_method_chain :folder, :lazy_load
        }
      end
    end

    module FolderedClassMethods
      # The has_folder? method is used to prevent multiple calls to has_folder, but might possibly be useful elsewhere.

      def has_folder?
        true
      end
    end

    module FolderedInstanceMethods
      #
      # Folders are lazy-created. That is, when we need it, we make it. This is achieved by chaining the `:folder` 
      # association method and creating a folder if none exists. This method definition must occur after the association 
      # has been defined.
      #
      def folder_with_lazy_load
        folder_without_lazy_load || self.create_folder(:parent => get_parent_folder)
      end

      #
      # Here we refer to the class variable defined during `has_folder` configuration. If it exists, we will put our folder 
      # inside that of the named associate. The containing folder might be created as a side effect.
      #
      def get_parent_folder
        pfh = self.class.class_variable_get(:"@@parent_folder_holder")
        if pfh && holder = send(pfh.to_sym)
          holder.folder
        else
          # otherwise we want a root folder like /Events
          Droom::Folder.find_or_create_by_slug_and_parent_id(self.class.to_s.titlecase.split('/').last.pluralize, nil)
        end
      end

      # Create a new document in our folder, with the supplied properties.
      #
      def add_document(attributes)
        folder.documents.create(attributes)
      end

      # Move an existing document into our folder.
      #
      def receive_document(doc)
        folder.documents << doc
      end

    end
  end

end