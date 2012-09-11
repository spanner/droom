require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::Document do
  
  before do
    # @site = Page.current_site = FactoryGirl.create(:test)
  end
  
  it "should have a groups association" do
    Droom::Document.reflect_on_association(:groups).should_not be_nil
    download = FactoryGirl.create(:grouped)
    download.groups.any?.should be_true
    download.groups.size.should == 2
  end

  it "should have a document attachment" do
    ["document", "document=", "document?"].each do |meth|
      Droom::Document.instance_methods.should include(meth)
    end
  end
  
  it "should validate file presence" do
    doc = FactoryGirl.create(:ungrouped)
    doc.should be_valid
    doc.document = nil
    doc.should_not be_valid
    doc.errors.on(:document).should_not be_nil
  end

  it "url should point to /secure_download " do
    doc = FactoryGirl.create(:grouped)
    doc.document.url.should =~ /^\/secure_download\/#{doc.id}/
  end

  it "path should be outside public site" do
    doc = FactoryGirl.create(:grouped)
    doc.document.path.should_not =~ /^#{RAILS_ROOT}\/public/
  end

end
