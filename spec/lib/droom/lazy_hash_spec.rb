require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::LazyHash do
  it "should be a Hash" do
    Droom::LazyHash is_a? Hash
  end
end
