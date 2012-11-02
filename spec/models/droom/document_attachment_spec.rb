require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::DocumentAttachment do
  before :each do
    @document = FactoryGirl.create(:document)
    @group = FactoryGirl.create(:group)
    @person = FactoryGirl.create(:person)
    @person.admit_to(@group)
    @da = FactoryGirl.create(:document_attachment, :attachee => @group, :document => @document)
  end
  
  describe "document_links" do
    it "should be created automatically" do
      @person.document_attachments.should include(@da)
    end
  end
  
  describe "slug" do
    describe "when attached" do
      it "should be the same as the slug of whatever we are attached to" do
        @da.slug.should == @group.slug
      end
    end
    
    describe "when unattached" do
      before do
        @loose = FactoryGirl.create(:document_attachment, :document => @document)
      end
      
      it "should say so" do
        @loose.slug.should == 'Unattached'
      end
    end
  end

end
