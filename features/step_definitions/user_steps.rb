Given /^a user$/ do
  @me ||= FactoryGirl.create(
    :user,
    :name => "Mike",
    :email => "mike@spanner.org",
    :password => "password",
    :password_confirmation => "password"
  )
  @me.reload
end

Given /^an active user$/ do
  step "a user"
  @me.activate!
end

Given /^a (?:signed|logged) in user$/ do
  step "a user"
  login
end

When /^I (?:sign|log) in$/ do
  step "I visit the login page"
  fill_in 'user_email', :with => @me.email
  fill_in 'user_password', :with => @me.password
  click_button "Sign in"
  save_and_open_page
end

Then /^I should be (?:signed|logged) in$/ do
  assert page.has_content?('login successful')
end

Given /^I (?:am on|go to|visit) (.*)$/ do |page_name|
  visit path_to(page_name)
end

When /^I change my (.*)$/ do |field|
  step "I go to the edit user page"
  fill_in "user_email", :with => "different@spanner.org"
end

Then /^my (.*) should have changed$/ do |field|
  # original different to current
end