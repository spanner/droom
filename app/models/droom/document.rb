module Droom
  class Document < ActiveRecord::Base
    attr_accessible :name, :file

    belongs_to :created_by, :class_name => 'User'
    has_many :attachments
    has_attached_file :file
    
    validates :file, :presence => true
    default_scope order('updated_at DESC, created_at DESC')

    def file_ok?
      self.file.exists?
    end

  end
end
