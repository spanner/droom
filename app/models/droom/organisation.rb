module Droom
  class Organisation < Droom::DroomRecord
    include Droom::Concerns::Tagged
    include Droom::Concerns::Imaged
    include Droom::Concerns::Suggested

    has_many :users
    belongs_to :organisation_type, optional: true
    belongs_to :owner, optional: true, class_name: 'Droom::User'

    has_one_attached :logo

    LOGO_VARIANTS = {
      standard: { resize_to_fill: [520, 520], strip: true },
      icon: { resize_to_fill: [32, 32], strip: true },
      thumb: { resize_to_fill: [130, 130], strip: true }
    }.freeze

    scope :added_since, -> date { where("created_at > ?", date) }
    scope :by_date, -> { order(created_at: :asc) }
    scope :external, -> { where(external: true) }
    scope :internal, -> { where(external: false) }

    scope :matching, -> fragment {
      fragment = "%#{fragment}%"
      where('droom_organisations.name ILIKE :f', :f => fragment)
    }

    default_scope -> {order("name ASC")}

    after_save :capture_owner

    # supports org-merge
    attr_accessor :other_id
    
    def self.for_selection(with_external=false)
      organisations = order("name asc")
      organisations = organisations.where(external: false) unless with_external
      organisations.map{|f| [f.name, f.id] }.unshift(['', ''])
    end

    def self.for_selection_with_owner(with_external=false)
      organisations = order("name asc").includes(:owner)
      organisations = organisations.where(external: false) unless with_external
      organisations.map{|o| ["#{o.name} (#{o.owner_name || 'No owner'})", o.id] }.unshift(['', ''])
    end

    def self.matching_email(email)
      domain = email.split('@').last
      where(joinable: true, email_domain: domain)
    end

    def administrator_ids
      users.where(organisation_admin: true).pluck(:id)
    end

    def administrator_ids=(ids)
      users.update_all(organisation_admin: false)
      users.where(id: ids).update_all(organisation_admin: true)
    end

    def logo?
      logo.attached?
    end

    def logo_url(style = :standard, _decache = true)
      return unless logo?
      attachment_variant_url(logo, LOGO_VARIANTS[style.to_sym] || LOGO_VARIANTS[:standard])
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

    def subsume(org)
      Droom::Organisation.transaction do
        self.users << org.users
        self.tags << org.tags
        self.chinese_name = org.chinese_name unless chinese_name?
        self.description = org.description unless description?
        self.logo = org.logo unless logo?
        self.owner = org.owner unless owner
        subsume_other_resources(org)
        self.save
        org.destroy
      end
    end

    def subsume_other_resources(org)
      # noop here
    end

    def capture_owner
      unless owner
        if user = users.first
          update_column :owner_id, user.id
          user.update_column :organisation_admin,  true
        end
      end
    end

    ## Search
    #
    searchkick _all: false, callbacks: :async, default_fields: [:name, :chinese_name, :description], highlight: [:name, :chinese_name, :description], word_start: [:name, :chinese_name, :description]

    def search_data
      {
        type: "droom/organisation",
        id: id,
        name: name || "",
        chinese_name: chinese_name || "",
        owner_name: owner_name,
        description: description,
        tags: tag_names,
        all_tags: tags_with_synonyms,
        people: users.map(&:name).join(', '),
        external: external?,
        created_at: created_at
      }
    end

    def owner_name
      owner.name if owner
    end

  end
end