require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::Person do
  
  before :each do
    @person = FactoryGirl.create(:person, :name => "Tester")
  end
  
  describe "DAV storage" do
    it "should be able to create a single DAV folder" do
      filename = rand(36**12).to_s(36)
      @person.create_dav_directory("just_testing")
      File.exist?(Rails.root + "#{Droom.dav_root}/#{@person.id}/just_testing").should be_true
    end
    
    it "should be able to create folders for all of its events and groups" do
      event = FactoryGirl.create(:simple_event, :name => "Event something")
      group = FactoryGirl.create(:group, :name => "Group something")
      @person.invite_to(event)
      @person.admit_to(group)
      @person.create_and_update_dav_directories
      File.exist?(Rails.root + "#{Droom.dav_root}/#{@person.id}/unattached").should be_true
      File.exist?(Rails.root + "#{Droom.dav_root}/#{@person.id}/#{event.slug}").should be_true
      File.exist?(Rails.root + "#{Droom.dav_root}/#{@person.id}/#{group.slug}").should be_true
    end
  end
  
  describe "visibility" do
    before do
      @friend = FactoryGirl.create(:person, :name => "Friend")
      @stranger = FactoryGirl.create(:person, :name => "Stranger")
      @publicist = FactoryGirl.create(:public_person, :name => "Public figure")
      @group = FactoryGirl.create(:group)
      @person.admit_to(@group)
      @friend.admit_to(@group)
    end
    
    it "should be able to see people with whom groups are shared" do
      Droom::Person.visible_to(@person).should include(@friend)
    end
    
    it "should not be able to see people without shared groups" do
      Droom::Person.visible_to(@person).should_not include(@stranger)
      @friend.expel_from(@group)
      Droom::Person.visible_to(@person).should_not include(@friend)
    end

    it "should be able to see public people" do
      Droom::Person.visible_to(@person).should include(@publicist)
    end
  end
  
end
