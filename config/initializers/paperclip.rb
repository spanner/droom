Paperclip.interpolates :person do |attachment, style|
  attachment.instance.person_id
end

Paperclip.interpolates :slug do |attachment, style|
  attachment.instance.slug
end

Paperclip.interpolates :document do |attachment, style|
  attachment.instance.document.filename
end
