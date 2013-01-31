require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::Membership do
  before :each do
    @person = FactoryGirl.create(:person)
    @group = FactoryGirl.create(:group)
    @membership = FactoryGirl.create(:membership, :person => @person, :group => @group)
  end
end
