module Droom
  class Permission < Droom::DroomRecord
    belongs_to :service
    has_many :group_permissions, :dependent => :destroy
    has_many :user_permissions, :dependent => :destroy
    acts_as_list :scope => :service_id
    before_save :set_slug

    validates :slug, :uniqueness => true

  protected
    
    def flat_name
      name.underscore..gsub(/\s+/, '_')
    end

    def set_slug
      self.slug ||= [service.slug, self.flat_name].join('.')
    end
  end
end