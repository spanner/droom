When /^I add an event$/ do
  step "I visit the new event page"
  save_and_open_page
  fill_in "event_name", :with => "event"
  fill_in "event_start_time", :with => 1.month.from_now
  save_and_open_page
  click_button "Save event"
end