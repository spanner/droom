require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::AgendaCategory do
  context "Creation" do
    before :each do
      @event = FactoryGirl.create(:simple_event)
      @category = FactoryGirl.create(:category)
      @agenda = FactoryGirl.create(:agenda_category, :event => @event, :category => @category)
    end
    it "should create a subfolder of the event's folder" do
      @agenda.folder.parent.should eq @event.folder
    end
    
  end
end
