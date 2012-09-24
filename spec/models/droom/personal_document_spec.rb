require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::PersonalDocument do
  
  before :each do
    @document = FactoryGirl.create(:document)
    @da = @document.document_attachments.create()
    @person = FactoryGirl.create(:person)
    @pd = FactoryGirl.create(:personal_document, :document_attachment => @da, :person => @person)
  end
  
  it "should have a document_attachment association" do
    Droom::PersonalDocument.reflect_on_association(:document_attachment).macro.should == :belongs_to
  end

  describe "on creation" do
    it "should clone its document file" do
      @pd.file_file_name.should == @document.file_file_name
    end
    it "should record its document version" do
      @document.version.should == 1
      @pd.version.should == @document.version
    end
    it "should record its file fingerprint" do
      @pd.file_fingerprint.should_not == 0
      @pd.file_changed?.should_not be_true
    end
    it "should save its file within the webdav folder of its person" do
      @pd.file.path.should == "#{Rails.root()}/webdav/#{@person.id}/#{@da.slug}/#{@pd.file_file_name}"
    end
    it "should save its file to a subfolder named by its attachment to event or group"
  end
  
  describe "when the file has been edited" do
    before :each do
      FileUtils.copy('/private/var/www/gems/droom/spec/fixtures/images/frog.png', @pd.file.path)
    end
    it "file_changed? should be true" do
      @pd.file_changed?.should == true
    end
    it "file_touched? should be true" do
      sleep(1)
      FileUtils.touch(@pd.file.path)
      @pd.file_touched?.should == true
    end
  end
  
  describe "when only the file modification date has changed" do
    before :each do
      sleep(1)
      FileUtils.touch(@pd.file.path)
    end
    it "file_changed? should be false" do
      @pd.file_changed?.should == false
    end
    it "file_touched? should be true" do
      @pd.file_touched?.should == true
    end
  end
  
  describe "recloning" do
    # reclone is called from the document when its file changes
    describe "after no file changes" do
      it "should clone the new file" do
    end
    
    describe "after file changes" do
      it "should archive the old file with a version suffix" do
        
      end
      it "should clone the new file"
      it "should receive the new document version"
      it "should record the new file fingerprint"
    end
  end


end
