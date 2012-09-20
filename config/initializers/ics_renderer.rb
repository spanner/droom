Mime::Type.register 'text/calendar', :ics

ActionController::Renderers.add :ics do |object, options|
  self.content_type ||= Mime::ICS
  self.response_body = RiCal.Calendar do |cal|
    [object].flatten.each do
      cal.add_subcomponent(object.to_rical) 
    end
  end
end
