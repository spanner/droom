require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::MailingListMembership do
  before :each do
    @person = FactoryGirl.create(:person)
    @group = FactoryGirl.create(:group)
    @membership = FactoryGirl.create(:membership, :person => @person, :group => @group)
    @mlm = @membership.mailing_list_membership
  end
  
  context "configuration:" do
    it "should try to open a custom mailman connection"
    it "should revert to the local mlm table if that doesn't work"
  end

  context "associations:" do
    it "should have a membership"
    it "should get an address from the membership's person"
    it "should get a listname from the membership's group"
  end
  
  context "creation:" do
    it "should get sensible default values"
    it "should get configured digest and nomail values"
  end
  
  context "translation" do
    context "setting a Y/N column" do
      it "should translate false to N"
      it "should translate true to Y"
      it "should translate 0 to N"
      it "should translate 1 to Y"
      it "should let N through"
      it "should let Y through"
    end
    context "getting a Y/N column" do
      it "should translate N to false"
      it "should translate Y to true"
    end
  end
end
