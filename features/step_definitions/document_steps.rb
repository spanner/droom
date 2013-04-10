When /^I add a document$/ do
  step "I am on the dashboard"
  click_link "Library"
  click_link "Add a document"
  # attach document
  fill_in "document_name", :with => "document"
  click_button "Save event"
end
