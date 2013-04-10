Given /^a person$/ do
  @person = FactoryGirl.create(
    :person,
    :invite_on_creation => true,
    :name => "Mike",
    :email => "mike@spanner.org"
  )
  @person.reload
  email = ActionMailer::Base.deliveries.last.parts.first.body.raw_source
  @invitation_link = /.*http:\/\/dummy.host(.*)\n.*/.match(email)[1]
end