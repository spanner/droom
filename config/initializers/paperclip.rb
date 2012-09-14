Paperclip.interpolates :person do |attachment, style|
  attachment.instance.person_id
end

# Slug in this context will be the identifying string for either the group or the event
# to which our document_attachment is attached. If none is present, we use 'unattached'.
#
Paperclip.interpolates :slug do |attachment, style|
  attachment.instance.slug
end
