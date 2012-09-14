require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::PersonalDocument do
  
  it "should have a document_attachment association"

  describe "on creation" do
    it "should clone its document file"
    it "should record its document version"
    it "should record its file fingerprint"
    it "should save its file within the webdav folder of its person"
    it "should save its file to a subfolder named by its attachment to event or group"
  end
  
  describe "when the file has been edited" do
    it "file_changed? should be true"
    it "file_touched? should be true"
  end
  
  describe "when only the file modification date has changed" do
    it "file_changed? should be false"
    it "file_touched? should be true"
  end
  
  describe "recloning" do
    # reclone is called from the document when its file changes
    describe "after no file changes" do
      it "should clone the new file"
    end
    
    describe "after file changes" do
      it "should archive the old file with a version suffix"
      it "should clone the new file"
      it "should receive the new document version"
      it "should record the new file fingerprint"
    end
  end


end
