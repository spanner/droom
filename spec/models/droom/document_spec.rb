require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::Document do
  
  describe "on creation" do
    it "should get a version number of 1"
  end
  
  describe "on update" do
    describe "if its file has changed" do
      it "should increment its version number"
      it "should trigger the update of its personal_document clones"
    end
    
    describe "if its file has not changed" do
      it "should not increment its version number"
      it "should not trigger the update of its personal_document clones"
    end
  end
  
end
 