require 'paperclip'

Paperclip.interpolates :user do |attachment, style|
  attachment.instance.user_id
end

# Slug in this context will be the identifying string for either the group or the event
# to which our document_attachment is attached. If none is present, we use 'unattached'.
#
Paperclip.interpolates :slug do |attachment, style|
  attachment.instance.slug
end

Paperclip.interpolates :category do |attachment, style|
  attachment.instance.category
end

Paperclip.interpolates :category_and_slug do |attachment, style|
  fragment = attachment.instance.slug
  fragment = "#{fragment}/#{attachment.instance.category.slug}" if attachment.instance.category
  fragment
end
