require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::LazyHash do
  it "should be a Hash" do
    Droom::LazyHash.new({}).is_a? Hash
  end
  it "initializing with a normal hash should create the right nested structure" do
    hash = {:object => {:key => "value"}}
    lazy_hash = Droom::LazyHash.new(hash)
    lazy_hash.should eq hash
  end
  it "split_path, when given a colon-separated string, should turn this:that:other into [:this, ['that', 'other]]." do
    lazy_hash = Droom::LazyHash.new()
    array = lazy_hash.split_path("this:that:other")
    array[0].should eq :this
    array[1].should eq ["that", "other"]
  end
  describe "get(key) and set(key) should do the right thing with" do
    before :each do
      @lazy_hash = Droom::LazyHash.new()
    end
    it "short keys" do
      @lazy_hash.set("this", "that")
      @lazy_hash.get("this").should eq "that"
    end
    it "long keys" do
      @lazy_hash.set("this:that", "other")
      @lazy_hash.get("this:that").should eq "other"
      this = {:that => "other"}
      @lazy_hash.get("this").should eq this
    end
  end
end
