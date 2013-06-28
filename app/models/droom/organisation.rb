module Droom
  class Organisation < ActiveRecord::Base
    attr_accessible :name, :description, :created_by, :owner, :url
    has_many :users
    belongs_to :owner, :class_name => 'Droom::User'
    belongs_to :created_by, :class_name => 'Droom::User'

    def self.for_selection
      organisations = self.order("name asc").map{|f| [f.name, f.id] }
      organisations.unshift(['', ''])
      organisations
    end

    def url_with_protocol
      url =~ /^https?:\/\// ? url : "http://#{url}"
    end

    def url_without_protocol
      url.sub(/^https?:\/\//, '')
    end
  end
end