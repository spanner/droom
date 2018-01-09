module Droom
  class Organisation < ApplicationRecord
    has_many :users
    has_many :images, through: :users
    has_many :videos, through: :users

    belongs_to :organisation_type
    belongs_to :owner, :class_name => 'Droom::User'
    accepts_nested_attributes_for :owner

    has_attached_file :logo,
                      :default_url => nil,
                      :styles => {
                        :standard => "520x520#",
                        :icon => "32x32#",
                        :thumb => "130x130#"
                      }
    do_not_validate_attachment_file_type :logo

    scope :added_since, -> date { where("created_at > ?", date)}
    default_scope -> {order("name ASC")}

    def self.for_selection
      organisations = self.order("name asc").map{|f| [f.name, f.id] }
      organisations.unshift(['', ''])
      organisations
    end

    def logo_url(style=:original, decache=true)
      if logo?
        url = logo.url(style, decache)
        url.sub(/^\//, "#{Settings.protocol}://#{Settings.host}/")
      end
    end

    # logo_data should be a fully specified data: url in base64 with prefix. Paperclip knows what to do with it.
    #
    def logo_data=(data_uri)
      if data_uri.present?
        self.logo = data_uri
      end
    end

    # If logo_data is given then the file name should be also supplied as `logo_name`.
    # You normally want to call this method after logo_url= or logo_data=, eg by ordering
    # parameters in the controller.
    #
    def logo_name=(name)
      self.logo_file_name = name
    end

    def url_with_protocol
      url =~ /^https?:\/\// ? url : "http://#{url}"
    end

    def url_without_protocol
      url.sub(/^https?:\/\//, '')
    end

  end
end