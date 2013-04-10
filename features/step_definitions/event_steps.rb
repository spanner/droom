When /^I add an event$/ do
  step "I am on the dashboard"
  click_link "Calendar"
  click_link "Add an event"
  fill_in "event_name", :with => "event"
  fill_in "event_start_time", :with => 1.month.from_now
  click_button "Save event"
end

Then /^the event should be created$/ do
  assert page.has_content?("Event 'event' created")
end