require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::Person, :solr => true do

  before :each do
    @person = FactoryGirl.create(:person, :name => "Tester")
  end

  describe "visibility" do
    before do
      @friend = FactoryGirl.create(:person, :name => "Friend")
      @stranger = FactoryGirl.create(:person, :name => "Stranger")
      @publicist = FactoryGirl.create(:public_person, :name => "Public figure")
      @elvis = FactoryGirl.create(:private_person, :name => "Elvis")
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

    it "should never be able to see private people" do
      Droom::Person.visible_to(@person).should_not include(@elvis)
    end
  end

end
