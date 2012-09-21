Mime::Type.register 'text/vcard', :vcf

ActionController::Renderers.add :vcf do |object, options|
  self.content_type ||= 'text/vcard'
  self.response_body  = object.respond_to?(:to_vcf) ? object.to_vcf : object
end

# Mime::ICS is already defined

ActionController::Renderers.add :ics do |object, options|
  self.content_type ||= 'text/calendar'
  self.response_body = object.respond_to?(:to_ics) ? object.to_ics : object
end
