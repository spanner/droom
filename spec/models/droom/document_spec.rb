require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::Document, :solr => true do

  context "Housekeeping:" do
    before :each do
      @document = FactoryGirl.create(:document)
    end

    describe "on creation" do
      it "should get a version number of 1" do
        @document.version.should == 1
      end
    end

    describe "on update" do
      describe "if its file has changed" do
        it "should trigger a version update" do
          @document.file = Rack::Test::UploadedFile.new(Droom::Engine.root() + 'spec/fixtures/images/frog.png', 'image/png')
          @document.save
          @document.version.should == 2
        end
      end

      describe "if its file has not changed" do
        it "should not trigger a version update" do
          @document.name = "something else"
          @document.save
          @document.version.should == 1
        end
      end
    end
  end

  context "Visibility:" do
    before :each do
      @document = FactoryGirl.create(:document)
      @public_document = FactoryGirl.create(:public_document)
      @person = FactoryGirl.create(:person)
      @event = FactoryGirl.create(:simple_event)
    end

    it "should not be visible to unlinked people" do
      Droom::Document.visible_to(@person).should_not include(@document)
    end

    describe "when public" do
      it "should be visible to unlinked people" do
        Droom::Document.visible_to(@person).should include(@public_document)
      end
    end

    describe "when linked" do
      before do
        @document.attach_to(@event)
        @invitation = @person.invite_to(@event)
      end

      it "should be visible to linked people" do
        pending "change to rules on who can see what"
        Droom::Document.visible_to(@person).should include(@document)
      end

      it "should become invisible when people are deinvited" do
        @invitation.destroy
        Droom::Document.visible_to(@person).should_not include(@document)
      end

      it "should become invisible when detached" do
        @document.detach_from(@event)
        Droom::Document.visible_to(@person).should_not include(@document)
      end
    end

  end
end
