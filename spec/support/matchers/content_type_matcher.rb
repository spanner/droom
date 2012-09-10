RSpec::Matchers.define :have_content_type do |content_type|
  match do |response|
    response.headers['Content-Type'] =~ /^#{content_type.to_s}/
  end
  
  failure_message_for_should do |response|
    "expected the response to have content type #{expected} but found #{response.headers['Content-Type']}"
  end

  failure_message_for_should_not do |response|
    "expected the response not to have content type #{expected} but found #{response.headers['Content-Type']}"
  end

  description do
    "have content type #{content_type}"
  end
end
