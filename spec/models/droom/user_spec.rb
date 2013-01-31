require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::User do
  before :each do
    @user = FactoryGirl.create(:user)
  end
  it "should have many preferences" do
    @user.should have_many :preferences
  end
  it "should have a pref method that returns a value" do
    @user.pref("email").should_not eq nil
  end
  it "should return the right default preference where it is expected" do
    @user.pref('dropbox:everything').should be_false
  end
  it "should create a Preference object when you set a preference with user.set_pref" do
    @user.preferences.count.should eq 0
    @user.set_pref("email:digest", true)
    @user.preferences.count.should eq 1
  end
  it "should return that preference object when reloaded and asked for pref(etc)" do
    @user.set_pref("email:digest", true)
    @user.preferences.count.should eq 1
    @user.reload
    @user.pref("email:digest").should be_true
  end
end
