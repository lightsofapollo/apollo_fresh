require 'spec_helper'
require 'apollo_fresh/format/date_components'

describe ApolloFresh::Format::DateComponents do

  def date_components(date)
    {
      'year' => date.year,
      'month' => date.month,
      'day' => date.day,
      'hour' => date.hour,
      'minute' => date.min,
      'tz' => date.zone
    }
  end

  subject { ApolloFresh::Format::DateComponents }

  before do
    @updated = Time.parse(record['updated'])
    @date = Time.parse(record['date'])
    @date_components = date_components(@date)
    @updated_components = date_components(@updated)    
  end

  # Invoice date fields are [date, updated]
  let(:record) do
    fresh_sample(:invoice)
  end

  let(:model) do
    klass = Class.new(ApolloFresh::Model) do
    end
    klass.class_eval do
      field :date, :type => DateTime
      store_in('_fake_mongo_class_1')
    end
    klass
  end

  it "Should parse date into a DateTime" do
    Time.parse(record['date']).to_datetime.is_a?(DateTime).should be_true
  end

  it "Should parse updated into a DateTime" do
    Time.parse(record['updated']).to_datetime.is_a?(DateTime).should be_true
  end

  context "When attached to a model" do
    before do
      model.send(:attach_formatter, subject, {:fields => [:date]})
    end

    context "When setting date" do
      let(:model_instance) do
        inst = model.new({:date => DateTime.now})
        inst.save
        inst
      end
    
      it "Should respond to date_dc" do
        model_instance.respond_to?(:date_dc).should be_true
      end

      it "Should automatically set date_dc based on date attribute" do
        model_instance.date_dc.should == date_components(model_instance.date)
      end

    end
    
  end

  context "When formatted string with options :fields => [:updated]" do
    let(:format) do
      subject.new(record.clone, :fields => [:updated])
    end

    before do
      @result = format.format!
    end

    it "Should have added updated_dc" do
      @result.should have_key('updated_dc')
    end

    it "Should have split updated into date components in updated_dc" do
      @result['updated_dc'].should == @updated_components
    end

    it "Should not have added date_dc" do
      @result.should_not have_key('date_dc')
    end

    it "Should not have modified other fields" do
      @result.delete(:updated_dc)
      record.each do |key, value|
        value.should == @result[key]
      end
    end

  end

  context "When formatting string with options {:fields => [:updated, :date]}" do

    let(:format) do
      subject.new(record.clone, :fields => [:updated, :date])
    end

    before do
      @result = format.format!
    end

    it "Should have added date_dc" do
      @result['date_dc'].should == @date_components
    end

    it "Should have added updated_dc" do
      @result['updated_dc'].should == @updated_components
    end

  end

end
