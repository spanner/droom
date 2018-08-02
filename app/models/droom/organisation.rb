module Droom
  class Organisation < ApplicationRecord
    include Droom::Concerns::Tagged

    has_many :users
    has_many :images, through: :users
    has_many :videos, through: :users

    belongs_to :organisation_type
    belongs_to :owner, :class_name => 'Droom::User'
    belongs_to :approved_by, :class_name => 'Droom::User'
    belongs_to :disapproved_by, :class_name => 'Droom::User'

    has_attached_file :image,
                      styles: {
                        thumb: ["128x96#", :png],
                        standard: ["640x480>", :jpg],
                        hero: ["1920x1080>", :jpg]
                      },
                      convert_options: {
                        thumb: "-strip",
                        standard: "-quality 50 -strip",
                        hero: "-quality 25 -strip"
                      }
    has_attached_file :logo,
                      default_url: :nil,
                      styles: {
                        standard: "520x520#",
                        icon: "32x32#",
                        thumb: "130x130#"
                      }

    validates_attachment :image, content_type: { content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"] }
    validates_attachment :logo, content_type: { content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"] }

    scope :added_since, -> date { where("created_at > ?", date) }
    scope :disapproved, -> { where.not(disapproved_at: nil) }
    scope :approved, -> { where.not(approved_at: nil) }
    scope :pending, -> { where(approved_at: nil, disapproved_at: nil) }
    scope :by_date, -> { order(created_at: :asc) }

    default_scope -> {order("name ASC")}

    def self.for_selection(with_external=false)
      organisations = order("name asc")
      organisations = organisations.where(external: false) unless with_external
      organisations.map{|f| [f.name, f.id] }.unshift(['', ''])
    end

    def self.from_signup(params)
      owner_params = params.delete :owner
      transaction do
        owner = Droom::User.from_email(owner_params[:email]).first || Droom::User.create(owner_params.merge(defer_confirmation: true, organisation_admin: true))
        org = Droom::Organisation.create(params.merge(owner: owner))
        org.users << owner
        org.reindex
        org
      end
    end

    def self.approve_all
      Searchkick.callbacks(:bulk) do
        u = Droom::User.first
        all.each {|o| o.approve!(u)}
      end
    end

    def self.disapprove_all
      Searchkick.callbacks(:bulk) do
        u = Droom::User.first
        all.each {|o| o.disapprove!(u)}
      end
    end

    # loud version for normal vetting process
    #
    def approve!(approving_user=nil)
      unless approved?
        self.update_attributes({
          approved_at: Time.now,
          approved_by: approving_user,
          disapproved_at: nil,
          disapproved_by: nil
        })
        send_welcome_message if approving_user
      end
    end

    # quiet version for seeding and admin tasks
    #
    def approve
      unless approved?
        self.update_attributes({
          approved_at: Time.now,
          disapproved_at: nil,
          disapproved_by: nil
        })
      end
    end

    def approved?
      approved_at?
    end

    def disapprove!(user)
      unless disapproved?
        self.update_attributes({
          disapproved_at: Time.now,
          disapproved_by: user,
          approved_at: nil,
          approved_by: nil
        })
      end
    end

    def disapproved?
      disapproved_at?
    end

    def pending?
      !approved? && !disapproved?
    end

    def send_welcome_message
      if owner
        owner.generate_confirmation_token unless owner.confirmation_token?
        Droom.mailer.send(:org_welcome, self, owner.confirmation_token).deliver_later
      end
    end

    def send_registration_confirmation_messages
      Droom.mailer.send(:org_confirmation, self).deliver_later
      Droom::User.gatekeepers.each do |admin|
        Droom.mailer.send(:org_notification, self, admin).deliver_later
      end
    end

    def administrator_ids
      users.where(organisation_admin: true).pluck(:id)
    end

    def administrator_ids=(ids)
      users.update_all(organisation_admin: false)
      users.where(id: ids).update_all(organisation_admin: true)
    end


    ## Images
    #
    def image_url(style=:standard, decache=true)
      if image?
        url = image.url(style, decache)
        url.sub(/^\//, "#{Settings.protocol}://#{Settings.host}/")
      else
        ""
      end
    end

    # Images usually come to us as data: urls but can also be given as actual url or assigned directly to image.
    #
    def image_url=(address)
      if address.present?
        self.image = URI(address)
      end
    rescue OpenURI::HTTPError => e
      Rails.logger.warn "Cannot read image url #{address} because: #{e}. Skipping."
    end

    # image_data should be a fully specified data: url in base64 with prefix. Paperclip knows what to do with it.
    #
    def image_data=(data_uri)
      if data_uri.present?
        self.image = data_uri
      end
    end

    # If image_data is given then the file name should be also supplied as `image_name`.
    # You normally want to call this method after image_url= or image_data=, eg by ordering
    # parameters in the controller.
    #
    def image_name=(name)
      self.image_file_name = name
    end

    def logo_url(style=:standard, decache=true)
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


    ## Social links
    #
    # Should really be implemented as a more future-proof social_links association, but this will get us started.
    #
    def instagram_url
      url_with_base(instagram_id, "instagram.com") if instagram_id?
    end

    def facebook_url
      url_with_base(facebook_page, "facebook.com") if facebook_page?
    end

    def twitter_url
      url_with_base(twitter_id, "twitter.com") if twitter_id?
    end

    def weibo_url
      url_with_base(weibo_id, "www.weibo.com") if weibo_id?
    end

    def url_with_base(fragment, base)
      if fragment =~ /#{Regexp.quote(base)}/i
        self.class.normalize_url(fragment)
      else
        path = fragment.sub(/^@/, '').strip
        URI.join("https://#{base}", path.strip).to_s
      end
    rescue URI::InvalidURIError
      ""
    end

    def url_without_base(base)
      social_id = url
      social_id.sub!(/http(s)?:\/\/(www\.)?/, '')
      social_id.sub!(/#{Regexp.quote(base)}(\/)?/, '')
      social_id
    end

    def self.normalize_url(url="")
      url = "http://#{url}" unless url.blank? or url =~ /^https?:\/\//
      url.strip
    end

    ## Search
    #
    searchkick _all: false, callbacks: :async, default_fields: [:name, :chinese_name, :description]

    def search_data
      {
        name: name || "",
        chinese_name: chinese_name || "",
        description: description,
        tags: tag_names,
        all_tags: tags_with_synonyms,
        people: users.map(&:name).join(', '),
        approved: approved?,
        external: external?,
        created_at: created_at
      }
    end

  end
end