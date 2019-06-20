require 'mustache'

module Droom::Concerns::Published
  extend ActiveSupport::Concern

  included do
    attr_accessor :publish_now, :publishing
    after_save :publish_if_publishing
    
    belongs_to :main_image, class_name: "Droom::Image"
    belongs_to :published_image, class_name: "Droom::Image"

    scope :published, -> {
      where.not(published_at: nil)
    }

    scope :by_publication_date, -> {
      order(published_at: :desc)
    }
  end

  def illustrated?
    !!main_image
  end

  def publish!
    unless publishing?
      update_attributes({
        published_title: title,
        published_subtitle: subtitle,
        published_intro: intro,
        published_image_id: main_image_id,
        published_image_weighting: main_image_weighting,
        published_content: content,
        published_at: Time.now
      })
    end
  end

  def published?
    published_at?
  end

  def publish_now?
    !!publish_now
  end

  def publishing?
    !!publishing
  end

  def publication_required?
    !published_at || published_at < updated_at
  end

  def render(attribute=:published_content)
    if renderable_attributes.include? attribute
      Rails.logger.warn "🚜 rendering #{attribute} with interpolations #{interpolations.inspect}"
      Mustache.render(read_attribute(attribute), interpolations)
    else
      ""
    end
  end

  def interpolations
    {
      site_title: I18n.t('site_title')
    }
  end

  protected

  def renderable_attributes
    [:title, :published_title, :intro, :published_intro, :subtitle, :published_subtitle, :content, :published_content]
  end

  def publish_if_publishing
    publish! if publish_now?
  end

end