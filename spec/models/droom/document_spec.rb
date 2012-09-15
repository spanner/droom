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
      before :each do
        @document.file = Rack::Test::UploadedFile.new(Droom::Engine.root() + 'spec/fixtures/images/frog.png', 'image/png')
        @document.save!
      end
      it "should increment its version number" do
        @document.version.should == 2
      end
      it "should trigger the update of its personal_document clones" do
        @document.personal_documents.each do |pd|
          pd.version.should == 2
        end
      end
    end
    
    describe "if its file has not changed" do
      before :each do
        @document.save!
      end
      it "should not increment its version number" do
        @document.version.should == 1
      end
      it "should not trigger the update of its personal_document clones" do
        @document.personal_documents.each do |pd|
          ###
        end
      end
    end
  end
  
end
