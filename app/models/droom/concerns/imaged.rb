module Droom::Concerns::Imaged
  extend ActiveSupport::Concern

  # The old paperclip styles, as ActiveStorage variant transformations.
  # Override `image_variants` in the including class to change the set.
  IMAGE_VARIANTS = {
    icon: { resize_to_fill: [32, 32], strip: true },
    thumb: { resize_to_fill: [128, 96], format: :png, strip: true },
    standard: { resize_to_limit: [640, 480], format: :jpg, quality: 50, strip: true },
    hero: { resize_to_limit: [1920, 1080], format: :jpg, quality: 25, strip: true }
  }.freeze

  included do
    has_one_attached :image
  end

  class_methods do
    def image_variants
      IMAGE_VARIANTS
    end
  end

  def image?
    image.attached?
  end

  def image_url(style = :standard, _decache = true)
    return "" unless image?
    style = :thumb if style.to_s == "thumbnail"
    spec = self.class.image_variants[style.to_sym] || self.class.image_variants[:standard]
    attachment_variant_url(image, spec)
  end

  # Absolute app-hosted URL (redirect route) for a variant of any attachment.
  def attachment_variant_url(attachment, spec)
    helpers = Rails.application.routes.url_helpers
    path = if attachment.variable?
      helpers.rails_representation_path(attachment.variant(spec), only_path: true)
    else
      helpers.rails_blob_path(attachment, only_path: true)
    end
    "#{Settings.protocol}://#{Settings.host}#{path}"
  end

  def icon_url(_decache = true)
    image_url(:icon)
  end

  def thumbnail_url(_decache = true)
    image_url(:thumb)
  end

  def thumbnail
    image_url(:thumb)
  end

  def icon
    image_url(:icon)
  end

end
