require 'spec_helper'

describe ApolloFresh::Format::HashedArray do

  subject { ApolloFresh::Format::HashedArray }

  let(:record) do
    fresh_sample(:invoice)
  end

  it "Should have a hashed array in lines" do
    record['lines'].is_a?(Hash).should be_true
  end

  context "After formatting" do

    let(:format) do
      subject.new(record.clone)
    end

    before do
      @result = format.format!
    end

    it "Should have remove hash wrapper around lines => line" do
      @result['lines'].class.should == Array
    end

    it "Should have the same contents without hash wrapper" do
      @result['lines'].should == record['lines']['line']
    end

    it "Should have not altered other fields" do
      @result.delete('lines')
      record.delete('lines')
      @result.each do |key, value|
        value.should == record[key]
      end
    end

  end


end