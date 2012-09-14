require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::DocumentAttachment do

  describe "not_personal_for" do
    it "should return all the document attachments that have not been personalised for the given user"
  end

  describe "slug" do
    it "should be the same as the slug of whatever we are attached to"
    it "or if unattached, should say so"
  end

end
