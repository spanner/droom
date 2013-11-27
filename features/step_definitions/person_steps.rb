Given /^a person$/ do
  @user = FactoryGirl.create(
    :user,
    :name => "Mike",
    :email => "mike@spanner.org"
  )
  @user.reload
  email = ActionMailer::Base.deliveries.last.parts.first.body.raw_source
  @invitation_link = /.*http:\/\/dummy.host(.*)\n.*/.match(email)[1]
end