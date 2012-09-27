require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::DocumentAttachment do
  before :each do
    @document = FactoryGirl.create(:document)
    @da = @document.document_attachments.create()
    @group = FactoryGirl.create(:group)
    @person = FactoryGirl.create(:person)
  end
  describe "not_personal_for" do
    it "should return all the document attachments that have not been personalised for the given user" do
      @da.attachee = @person
      Droom::DocumentAttachment.not_personal_for(@person)
    end
  end

  describe "slug" do
    it "should be the same as the slug of whatever we are attached to" do
      @da.attachee = @group
      @da.slug.should_not == 'Unattached'
      @da.slug.should == @group.slug
    end
    it "or if unattached, should say so" do
      @da.slug.should == 'Unattached'
    end
  end

end
