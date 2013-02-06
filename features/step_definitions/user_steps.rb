Given /^I am an invited user$/ do
  step "a person"
  @user = @person.user
end

When /^I (?:follow|click) the invitation email link$/ do
  visit @invitation_link
end

Given /^I am an active user$/ do
  step "I am an invited user"
  @user.activate!
  @user.password = "password"
  @user.save!
end

Given /^I am a (?:signed|logged) in user$/ do
  step "I am an active user"
  step "I log in"
end

Given /^I am an active administrator$/ do
  step "I am an active user"
  @user.admin = true
  @user.save!
end

Given /^I am a (?:signed|logged) in administrator$/ do
  step "I am an active administrator"
  step "I log in"
end

When /^I (?:sign|log) in$/ do
  step "I am on the dashboard"
  fill_in 'user_email', :with => @user.email
  fill_in 'user_password', :with => @user.password
  click_button "Sign in"
end

Then /^I should be (?:signed|logged) in$/ do
  assert page.has_content?('Signed In As')
end

Given /^I (?:am on|go to|visit) (.*)$/ do |page_name|
  visit path_to(page_name)
end

When /^I change my email$/ do
  step "I am on the dashboard"
  click_link "Preferences"
  fill_in "user_email", :with => "not_mike@spanner.org"
  click_button "Save changes"
end

Then /^my (.*) should have changed$/ do |field|
  step "my changes should have been saved"
end

When /^I fill in the welcome form$/ do
  fill_in "user_password", :with => "password"
  fill_in "user_password_confirmation", :with => "password"
  click_button "Continue"
end

Then /^my changes should have been saved$/ do
  assert page.has_content?('Thank you. Your preferences have been updated')
end

