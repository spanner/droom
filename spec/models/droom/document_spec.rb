require File.dirname(__FILE__) + '/../../spec_helper'
describe Droom::Document do
  
  before :each do
    @document = FactoryGirl.create(:document)
    @da = FactoryGirl.create(:document_attachment, :document => @document)
    @pd = FactoryGirl.create(:personal_document, :document_attachment => @da)
  end
  
  describe "on creation" do
    it "should get a version number of 1" do
      @document.version.should == 1
    end
  end
  
  describe "on update" do
    describe "if its file has changed" do
      it "should trigger a version update" do
        @document.should_receive(:refresh_personal_documents)
        @document.file = Rack::Test::UploadedFile.new(Droom::Engine.root() + 'spec/fixtures/images/frog.png', 'image/png')
        @document.save
        @document.version.should == 2
      end
    end
    
    describe "if its file has not changed" do
      it "should not trigger a version update" do
        @document.should_not_receive(:refresh_personal_documents)
        @document.name = "something else"
        @document.save
        @document.version.should == 1
      end
    end
  end
  
end
