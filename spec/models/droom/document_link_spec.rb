require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::DocumentLink do
  
  before :each do
    @document = FactoryGirl.create(:document)
    @person = FactoryGirl.create(:person)
    @group = FactoryGirl.create(:group)
    @person.admit_to(@group)
    @document.attach_to(@group)
  end

  it "should be created automatically" do
    @person.document_links.count.should == 1
    @person.documents.should include(@document)
  end
  
  it "should be destroyed automatically when group membership is revoked" do
    @person.expel_from(@group)
    @person.reload
    @person.documents.should_not include(@document)
  end

  it "should be destroyed automatically when document is no longer attached" do
    @document.detach_from(@group)
    @person.reload
    @person.documents.should_not include(@document)
  end

end