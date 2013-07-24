require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::Membership do
  before :each do
    @user = FactoryGirl.create(:user)
    @group = FactoryGirl.create(:group)
    @membership = FactoryGirl.create(:membership, :user => @user, :group => @group)
  end
  
  context "on creation" do
    it "should create a mailing list membership"
    it "should create personal folders"
    it "should cause documents to become visible_to people"
  end
  
  context "on destruction" do
    it "should destroy its mailing list membership"
    it "should destroy its personal folders"
    it "should cause documetns to stop being visible_to people"
  end
  
end
