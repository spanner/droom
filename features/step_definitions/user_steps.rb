Given /^a user$/ do
  @user ||= FactoryGirl.create(
    :user,
    :name => "Mike",
    :email => "mike@spanner.org",
    :password => "password",
    :password_confirmation => "password"
  )
  @user.reload
end

Given /^an invited user$/ do
  step "a person"
  ap @person
  ap @person.user
  @user = @person.user
end

When /^I follow the invitation email link$/ do
  step "I visit the welcome page"
  save_and_open_page
end

Given /^an active user$/ do
  step "a user"
  @user.activate!
end

Given /^a (?:signed|logged) in user$/ do
  step "an active user"
  login
end

When /^I (?:sign|log) in$/ do
  step "I visit the login page"
  fill_in 'user_email', :with => @user.email
  fill_in 'user_password', :with => @user.password
  click_button "Sign in"
end

Then /^I should be (?:signed|logged) in$/ do
  assert page.has_content?('Signed in As')
end

Given /^I (?:am on|go to|visit) (.*)$/ do |page_name|
  visit path_to(page_name)
end

When /^I change my email$/ do
  step "I go to the preferences page"
  save_and_open_page
  pending
end

Then /^my email should have changed$/ do
  pending
  # original different to current
end

When /^I sign up$/ do
  step "I visit the sign up page"
  pending
end
