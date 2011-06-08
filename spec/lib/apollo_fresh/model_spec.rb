require 'spec_helper'

describe ApolloFresh::Model do
  
  subject do
    klass = Class.new(ApolloFresh::Model)
    klass.send(:store_in, '_testing_apollo_fresh_model')
    klass
  end

  let!(:test_api) do
    Class.new(ApolloFresh::Api)
  end

  let!(:parent) do
    ApolloFresh::Model
  end


  let(:all_invoices) do
    fresh_sample(:invoices, 40, 40, 1, 1..40)['invoice'].index_by {|obj| obj['invoice_id']}
  end
  
  before(:each) do
    subject.resource = 'invoice'
  end

  it "Should automatically add model to auto update" do
    ApolloFresh::Update.auto_update?(subject).should === true
  end

  it "Should include Mongoid::Document" do
    subject.included_modules.should include(Mongoid::Document)
  end

  before(:each) do
    subject.model = ApolloFresh::Api
  end

  describe "#self.population_formatters" do
    context "When formatters are present on both child and parent" do

      let!(:child_formatter) do
        flexmock('child-formatter', {
          :format! => '',
          :instance_methods => ['format!']
        })
      end

      let!(:parent_formatter) do
        flexmock('parent-formatter', {
          :format! => '',
          :instance_methods => ['format!']
        })
      end

      after do
        parent.remove_formatter(parent_formatter)
        subject.remove_formatter(child_formatter)
        subject.remove_formatter(parent_formatter)
      end

      before do
        parent.attach_formatter(parent_formatter, {:parent => true})
        subject.attach_formatter(child_formatter, {:child => true})
        subject.attach_formatter(parent_formatter, {:child => true})

        @formatters = subject.population_formatters
      end

      it "Should return an Array of formatters [{formatter => options}, etc...]" do
        @formatters.is_a?(Array).should be_true
      end

      it "Should have parent formatter with :parent => true in parent" do
        expected = {parent_formatter => {:parent => true}}
        @formatters.should include(expected)
      end

      it "Should have child formatter with :child => true in child" do
        expected = {child_formatter => {:child => true}}
        @formatters.should include(expected)
      end

      it "Should have parent formatter with child => true in child" do
        expected = {parent_formatter => {:child => true}}
        @formatters.should include(expected)
      end

    end
  end

  describe "#self.attach_formatter" do

    after do
      subject.remove_formatter(formatter)
    end

    let(:formatter) do
      flexmock('formatter-attach', {
        :format! => '',
        :instance_methods => ['format!']
      })
    end

    it "Should raise an exception when providing an object without a format! instance method" do
      lambda { subject.attach_formatter(Class.new)  }.should raise_error /must provide format!/
    end

    it "Should attach formatter to object" do
      subject.attach_formatter(formatter, {:yey => true})
      subject.should have_formatter(formatter)
    end

    context "When formatter has self.model_include function" do
      let!(:formatter) do
        Class.new do

          def initialize(record, options = {})

          end

          def format!()
            
          end

          class << self
            def attached

            end
          end
        end
      end

      after do
        subject.remove_formatter(formatter)
      end

      it "Should call model include method when attached with model class as an argument" do
        flexmock(formatter).should_receive(:attached).with(subject, {:options => true}).once
        subject.attach_formatter(formatter, :options => true)
      end

    end

    context "When attaching from base object children should inherit formatters" do
      before do
        parent.attach_formatter(formatter)
      end

      after do
        parent.remove_formatter(formatter)
      end

      it "Should have formatter in parent" do
        parent.should have_formatter(formatter)
      end

      it "Should have formatter in child" do
        subject._formatters.should have_key(formatter)
      end
    end

    context "When attaching formatter to child, sibling and parent should not inherit" do
      let!(:sibling) do
        Class.new(parent)
      end

      after do
        subject.remove_formatter(formatter)
      end

      before do
        subject.attach_formatter(formatter)
      end

      it "Should not have added formatter to sibling" do
        sibling.should_not have_formatter(formatter)
      end

      it "Should not have added formatter to parent" do
        sibling.should_not have_formatter(formatter)
      end

      it "Should have attached formatter to self" do
        subject.should have_formatter(formatter)
      end

    end

  end

  context "#self.remove_formatter" do
    let(:formatter) do
      flexmock('formatter-remove', {
        :format! => '',
        :instance_methods => ['format!']
      })
    end

    after do
      subject.remove_formatter(formatter)
      parent.remove_formatter(formatter)
    end

    context "When removing formatter from child" do
      before do
        subject.attach_formatter(formatter)
      end

      after do
        subject.remove_formatter(formatter)
      end

      it "Should have formatter" do
        subject.should have_formatter(formatter)
      end

      it "Should not have formatter after removal" do
        subject.remove_formatter(formatter)
        subject.should_not have_formatter(formatter)
      end
    end

    context "When removing parent formatter from children" do
      before do
        parent.attach_formatter(formatter)
        subject.remove_formatter(formatter)
      end

      it "Should still have formatter on parent" do
        parent.should have_formatter(formatter)
      end

      it "Should not have formatter on child" do
        subject.should_not have_formatter(formatter)
      end

    end

  end

  describe "#self.api" do
    it "Should return ApolloFresh::Model instance" do
      subject.api.should == ApolloFresh::Api
    end    
  end

  describe "#self.model" do
    before(:each) { subject.model = test_api }

    it "Should allow override of model" do
      subject.model.should == test_api
    end

    it "Should also have set api to new model" do
      subject.api.should == test_api
    end
  end

  describe "#self.resource" do
    before(:each) { subject.resource = 'resource_name' }

    it "Should allow us to set the resource" do
      subject.resource.should == 'resource_name'
    end

    it "Should call key when setting resource using \#{resource}_id" do
      model = flexmock(subject)
      model.should_receive(:key).with('invoice_id').once
      model.resource = 'invoice'
    end
  end
  
  describe "#self.populate!" do
    context "When loading all data into the model for the first time" do
      before(:each) do
        @api = flexmock(subject.api).should_receive(:all!).and_return(all_invoices)
      end

      it "Should populate collection with records from :all!" do
        @api.once
        subject.populate!
        count = subject.count()
        all = subject.all
        invoices = all_invoices.clone

        count.should == 40
        all.each do |object|
          invoices.should have_key(object.id)
          invoices.delete(object.id)
        end
        invoices.length.should == 0
      end
    end

    context "When updating collection and records have been removed from API" do
      let(:invoices) do
        fresh_sample(:invoices, 20, 20, 1, 1..20)['invoice'].index_by {|obj| obj['invoice_id']}
      end
      before(:each) do
        @api = flexmock(subject.api)
        @api.should_receive(:all!).and_return(all_invoices).once.ordered(:populate)
        @api.should_receive(:all!).and_return(invoices).once.ordered(:populate)

        subject.populate!.should be_true

      end

      it "Should only have records returned by the most recent all when success" do
        subject.populate!.should be_true
        all = subject.all
        count = subject.count
        invoices = self.invoices.clone

        count.should == 20
        all.each do |object|
          invoices.should have_key(object.id)
          invoices.delete(object.id)
        end
        invoices.length.should == 0
      end
    end

    context "With formatting by ApolloFresh::Format::DateComponents" do
      let(:invoices) do
        fresh_sample(:invoices, 20, 20, 1, 1..20)['invoice'].index_by {|obj| obj['invoice_id']}
      end

      let!(:formatters) do
        [{ApolloFresh::Format::DateComponents => {:fields => [:date]}}, {ApolloFresh::Format::HashedArray => {}}]
      end

      before do
        @api = flexmock(subject.api)
        @api.should_receive(:all!).and_return(invoices).once.ordered(:populate)
        flexmock(subject).should_receive(:population_formatters).once.and_return(formatters)
        subject.populate!
      end

      it "Should have added date_dc to records" do
        subject.first.date_dc.is_a?(Hash).should be_true
      end
    end


    context "With formatting by ApolloFresh::Format::HashedArray" do
      let(:invoices) do
        fresh_sample(:invoices, 20, 20, 1, 1..20)['invoice'].index_by {|obj| obj['invoice_id']}
      end

      let!(:formatters) do
        [{ApolloFresh::Format::HashedArray => {}}]
      end

      before do
        @api = flexmock(subject.api)
        @api.should_receive(:all!).and_return(invoices).once.ordered(:populate)
        flexmock(subject).should_receive(:population_formatters).once.and_return(formatters)
        subject.populate!
      end

      it "Should have removed the hash wrapper around lines" do
        subject.first.lines.is_a?(Array).should be_true
      end


    end

  end

  describe "#self.populate" do 
    before(:each) do
      @api = flexmock(subject.api)
      @api.should_receive(:all!).and_return(all_invoices).once.ordered(:populate)
      subject.populate!
    end

    it "Should update record in database when populating" do
      original = subject.find(:first, :conditions => {:id => '1'})

      populate_with = fresh_sample(:invoice, '1')
      populate_with['number'] = '10000001'

      subject.populate({'1' => populate_with})

      current = subject.find(:first, :conditions => {:id => '1'})

      current.id.should == original.id
      current.number.should == '10000001'
    end

  end

  context "When testing Mongo Capabilities" do
    
    let(:invoice) do
      fresh_sample(:invoice, '55')
    end

    context "When querying test row" do
      before(:each) do
        subject.create!(invoice.merge('mongo_test' => '1'))
        @object = subject.find(:first, :conditions => {'mongo_test' => '1'})
      end

      it "Lines should equal invoice.lines" do
        @object.lines.should == invoice['lines']
      end

      it "Should have id equal to invoice and and 55" do
        @object.id.should == '55'
        @object.id.should == @object.invoice_id
      end
    end
  end

end
