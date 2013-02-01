When /^I sign up$/ do
  visit path_to "the sign up page"
  fill_in 'person_email', :with => "will@spanner.org"
  fill_in 'person_name', :with => "Will"
  click_button "Sign up"
end

Given /^a person$/ do
  @person = FactoryGirl.create(
    :person,
    :invite_on_creation => true,
    :name => "Mike",
    :email => "mike@spanner.org"
  )
  @person.reload
end