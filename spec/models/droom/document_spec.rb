require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::Document, :solr => true do

  context "Visibility:" do
    before :each do
      @document = FactoryGirl.create(:document)
      @user = FactoryGirl.create(:user)
      @event = FactoryGirl.create(:simple_event)
    end

    it "should not be visible to unlinked people" do
      Droom::Document.visible_to(@user).should_not include(@document)
    end

    describe "when linked" do
      before do
        @document.attach_to(@event)
        @invitation = @user.invite_to(@event)
      end

      it "should be visible to linked people" do
        pending "change to rules on who can see what"
        Droom::Document.visible_to(@user).should include(@document)
      end

      it "should become invisible when people are deinvited" do
        @invitation.destroy
        Droom::Document.visible_to(@user).should_not include(@document)
      end

      it "should become invisible when detached" do
        @document.detach_from(@event)
        Droom::Document.visible_to(@user).should_not include(@document)
      end
    end

  end
end
