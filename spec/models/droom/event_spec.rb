require File.dirname(__FILE__) + '/../../spec_helper'
require 'awesome_print'
describe Droom::Event do
        
  describe "A simple event" do
    before do
      @event = FactoryGirl.create(:simple)
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
    before do 
      @event = FactoryGirl.create(:spanning)
    end
    
    it "should have the right duration" do
      @event.duration.should == 32.hours
    end
    
    it "should not be marked as all day" do
      @event.all_day?.should be_false
    end
  end

  describe "A repeating event" do
    before do 
      @event = FactoryGirl.create(:repeating)
      @event.send :update_occurrences
    end
    
    it "should have the right duration" do
      @event.duration.should == 90.minutes
    end
    
    it "should not be marked as all day" do
      @event.all_day?.should be_false
    end
    
    it "should have a recurrence rule" do
      @event.recurrence_rules.should_not be_empty
      @event.recurrence_rules.first.period.should == 'weekly'
      @event.recurrence_rules.first.interval.should == 1
      @event.recurrence_rules.first.limiting_count.should == 4
    end
    
    it "should have occurrences" do
      @event.occurrences.should_not be_empty
    end
    
    describe "recurring" do
      before do
        @occurrence = @event.occurrences.last
      end
      
      it "should have the right master" do
        @occurrence.master.should == @event
      end
      
      it "should resemble its master in most ways" do
        [:name, :description, :venue, :url, :duration].each do |att|
          @occurrence.send(att).should == @event.send(att)
        end
      end
      
      it "should have a different date and uuid" do
        [:start, :finish, :uuid].each do |att|
          @occurrence.send(att).should_not == @event.send(att)
        end
      end

    end
  end
end

