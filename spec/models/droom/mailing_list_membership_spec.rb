require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::MailingListMembership do
  before :each do
    @user = FactoryGirl.create(:user)
    @group = FactoryGirl.create(:group)
    @membership = FactoryGirl.create(:membership, :user => @user, :group => @group)
    @mlm = @membership.mailing_list_membership
  end
  
  context "configuration:" do
    it "should try to open a custom mailman connection"
    it "should revert to the local mlm table if that doesn't work"
  end

  context "associations:" do
    it "should have a membership" do
      @mlm.membership.should_not be_nil
      @mlm.membership.should eq @membership
    end
    it "should get an address from the membership's user" do
      @mlm.address.should_not be_nil
      @mlm.address.should eq @user.email
    end
    it "should get a listname from the membership's group" do
      @mlm.listname.should_not be_nil
      @mlm.listname.should eq @group.name
    end
  end

  context "creation:" do
    it "should get sensible default values" do
      @mlm.bi_lastnotice.should eq 0
      @mlm.bi_date.should eq 0
      @mlm.ack.should be_true
    end
    it "should get configured digest and nomail values" do
      @mlm.digest.should_not be_nil
      @mlm.nomail.should_not be_nil
    end
  end

  context "translation" do
    context "setting a Y/N column" do
      it "should translate false to N" do
        @mlm.nomail = false
        @mlm.attributes_before_type_cast["nomail"].should eq "N"
      end
      it "should translate true to Y" do
        @mlm.nomail = true
        @mlm.attributes_before_type_cast["nomail"].should eq "Y"
      end
      it "should translate 0 to N" do
        @mlm.nomail = 0
        @mlm.attributes_before_type_cast["nomail"].should eq "N"
      end
      it "should translate 1 to Y" do
        @mlm.nomail = 1
        @mlm.attributes_before_type_cast["nomail"].should eq "Y"
      end
      it "should let N through" do
        @mlm.nomail = "N"
        @mlm.attributes_before_type_cast["nomail"].should eq "N"
      end
      it "should let Y through" do
        @mlm.nomail = "Y"
        @mlm.attributes_before_type_cast["nomail"].should eq "Y"
      end
    end
    context "getting a Y/N column" do
      it "should translate N to false" do
        @mlm.nomail = "N"
        @mlm.nomail.should be_false
      end
      it "should translate Y to true" do
        @mlm.nomail = "Y"
        @mlm.nomail.should be_true
      end
    end
  end
end
