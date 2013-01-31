require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::Person, :solr => true do

  before :each do
    @person = FactoryGirl.create(:person, :name => "Tester")
  end

  describe "DAV storage" do
    it "should be able to create a single DAV folder", :solr => true do
      pending "create_dav_directory moved to personal folder and awaiting translation"
      filename = rand(36**12).to_s(36)
      @person.create_dav_directory("just_testing")
      File.exist?(Rails.root + "#{Droom.dav_root}/#{@person.id}/just_testing").should be_true
    end

    it "should be able to create folders for all of its events and groups" do
      pending "create_and_update_dav_directories moved to personal folder and awaiting translation"
      event = FactoryGirl.create(:simple_event, :name => "Event something")
      group = FactoryGirl.create(:group, :name => "Group something")

      group.attach(FactoryGirl.create(:document, :name => "Attached to group"))
      event.attach(FactoryGirl.create(:document, :name => "Attached to event"))

      @person.invite_to(event)
      @person.admit_to(group)
      @person.create_and_update_dav_directories
      File.exist?(Rails.root + "#{Droom.dav_root}/#{@person.id}/#{event.slug}").should be_true
      File.exist?(Rails.root + "#{Droom.dav_root}/#{@person.id}/#{group.slug}").should be_true
    end

    it "should be able to create a folder for directly-attached documents" do
      pending "create_and_update_dav_directories moved to personal folder and awaiting translation. attach method gone"
      document = FactoryGirl.create(:document, :name => "Loose Document")
      @person.attach(document)
      @person.create_and_update_dav_directories
      File.exist?(Rails.root + "#{Droom.dav_root}/#{@person.id}/Unattached").should be_true
    end
  end

  describe "visibility" do
    before do
      @friend = FactoryGirl.create(:person, :name => "Friend")
      @stranger = FactoryGirl.create(:person, :name => "Stranger")
      @publicist = FactoryGirl.create(:public_person, :name => "Public figure")
      @elvis = FactoryGirl.create(:shy_person, :name => "Elvis")
      @group = FactoryGirl.create(:group)
      @person.admit_to(@group)
      @friend.admit_to(@group)
      @elvis.admit_to(@group)
    end

    it "should be able to see people with whom groups are shared" do
      Droom::Person.visible_to(@person).should include(@friend)
    end

    it "should not be able to see people without shared groups" do
      Droom::Person.visible_to(@person).should_not include(@stranger)
      @friend.expel_from(@group)
      Droom::Person.visible_to(@person).should_not include(@friend)
    end

    it "should always be able to see public people" do
      Droom::Person.visible_to(@person).should include(@publicist)
    end

    it "should never be able to see shy people" do
      Droom::Person.visible_to(@person).should_not include(@elvis)
    end
  end

end
