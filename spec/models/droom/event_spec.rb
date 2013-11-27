require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::Event, :solr => true do
        
  describe "A simple event" do
    before :each do
      @event = FactoryGirl.create(:simple_event)
    end
    
    it "should be valid" do
      @event.valid?.should be_true
    end
    
    [:name, :start].each do |field|
      it "should not be valid without a #{field}" do
        @event.send "#{field}=".intern, nil
        @event.valid?.should be_false
      end
    end
    
    it "should not mind if it has no end date" do
      @event.finish.should be_nil
      @event.duration.should == 0
    end
    
    describe "can change its" do
      
      it "start time" do
        @event.start_time.should == Time.new(2009,11,03,18,30,00)
        @event.start_time = "01:00"
        @event.start_time.should == Time.new(2009,11,03,01,00,00)
      end
    
      it "start date" do
        @event.start_date.should == Date.new(2009,11,03)
        @event.start_date = "20 March 2013"
        @event.start_date.should == Date.new(2013,03,20)
      end

      it "finish time" do
        @event.finish_time.should == nil
        @event.finish_time = "9pm"
        @event.finish_time.should == Time.new(2009, 11, 3, 21, 0, 0)
      end

      it "finish date" do
        @event.finish_date.should == nil
        @event.finish_date = "30 April 2014"
        @event.finish_date.should == Date.new(2014,04,30)
      end
    end
  end

  describe "A spanning event" do
    before :each do 
      @event = FactoryGirl.create(:spanning_event)
    end
    
    it "should have the right duration" do
      @event.duration.should == 32.hours
    end
    
    it "should not be marked as all day" do
      @event.all_day?.should be_false
    end
  end

  describe "A repeating event" do
    before :each do 
      @event = FactoryGirl.create(:repeating_event)
      @event.send :update_occurrences
    end
    
    it "should have the right duration" do
      @event.duration.should == 90.minutes
    end
    
    it "should not be marked as all day" do
      @event.all_day?.should be_false
    end
  end

  describe "retrieval" do
    before :each do
      base = Time.new(2013, 1, 1, 9, 0, 0)
      40.times { |i| FactoryGirl.create(:closed_event, :start => base + i.days, :finish => base + i.days + 1.hour) }
      FactoryGirl.create(:closed_event, :start => base + 28.days, :finish => base + 32.days)
      
      @beg = Time.new(2013, 1, 5, 12, 0, 0)
      @end = Time.new(2013, 1, 15, 12, 0, 0)
      @span = Chronic.parse("January 2013", :guess => false)
    end
    
    it "should return all the events falling before a date" do
      
      # p "before beg: #{Droom::Event.before(@beg).map(&:name).join(',')}"
      
      Droom::Event.before(@beg).count.should == 5
      Droom::Event.before(@end).count.should == 15
    end
    
    it "should return all the events falling after a date" do
      Droom::Event.after(@beg).count.should == 36
      Droom::Event.after(@end).count.should == 26
    end
    
    it "should return all the events that start or end between two dates" do
      Droom::Event.coincident_with(@beg, @end).count.should == 10
    end

    it "should return all the events that overlap with a span" do
      Droom::Event.falling_within(@span).count.should == 32
    end
      
    it "should return all the events that lie within a span" do
      Droom::Event.in_span(@span).count.should == 31
    end
  end
end

