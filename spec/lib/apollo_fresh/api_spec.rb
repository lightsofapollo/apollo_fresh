require 'spec_helper'

describe ApolloFresh::Api do

  let(:klass) do
    ApolloFresh::Api
  end

  let(:child_klass) do
    Class.new(klass) do
    end
  end

  let(:config_file) do
    File.join(APOLLO_FRESH_ROOT, 'spec', 'support', 'resources', 'freshbooks.yml')
  end

  let(:child_config_file) do
    File.join(APOLLO_FRESH_ROOT, 'spec', 'support', 'resources', 'freshbooks-child.yml')
  end

  before(:each) do
    klass.resource = 'invoice'
    klass.config_file = config_file
  end

  after(:each) do
    [:api_url, :resource, :loaded_config_file, :config_file].each {|v| klass.send("#{v.to_s}=", nil)}
    child_klass.config_file = nil
  end

  it "Should have included module HTTParty" do
    klass.should include(HTTParty)
  end

  describe "#self.config_file=" do

    it "Should allow us to set config_file" do
      klass.config_file = config_file
      klass.config_file.should == config_file
    end

  end

  describe "#self.authenticate!" do
    before(:each) do
      klass.api_key = 'password'
    end

    it "should set basic_auth" do
      #Freshbooks uses api_key as username this is intentional
      model = flexmock(klass)
      model.should_receive(:basic_auth).with('password', 'X').once()

      klass.authenticate!
    end
  end

  describe "#self.loaded_config_file" do
    before(:each) { klass.load_config! }
    it "Should be same as config_file after load_config!" do
      klass.loaded_config_file.should == config_file
    end
  end

  describe "#self.has_config_loaded?" do

    context "When it has not loaded" do
      it "Should not be marked at loaded" do
        klass.should_not have_config_loaded
      end
    end

    context "When it has loaded" do
      before(:each) { klass.load_config! }
      
      it "Should be properly marked as loaded" do
        klass.should have_config_loaded
      end

      it "Should also have subclasses marked as loaded" do
        child_klass.should have_config_loaded
      end

      it "Should not mark subclass as loaded if config_file is different and not loaded" do
        child_klass.config_file = child_config_file
        child_klass.should_not have_config_loaded
      end

      it "Should mark subclass as loaded if config_file is different but loaded" do
        child_klass.config_file = child_config_file
        child_klass.load_config!
        child_klass.should have_config_loaded
      end
    end
  end

  describe "#self.load_config!" do
    context "When has not loaded" do
      it "Should call authenticate when loaded" do
        model = flexmock(klass)
        model.should_receive(:authenticate!).once()
        klass.load_config!
      end
    end

    context "When has loaded" do
      before(:each) { klass.load_config! }

      it "Should load config file and set api_key and api_url (uses database.yml format)" do
        api_key_will = 'test_key'
        api_url_will = 'test'

        klass.api_key.should == api_key_will
        klass.api_url.should == api_url_will
      end

      it "Should allow children to specify their own config file" do
        child_klass.config_file = child_config_file
        child_klass.load_config!

        api_key_will = 'c-test_key'
        api_url_will = 'c-test'

        child_klass.api_key.should == api_key_will
        child_klass.api_url.should == api_url_will
      end
    end
  end


  describe "#self.resource" do
    it "Should be set at the class level" do
      child_klass.resource = 'invoices'
      child_klass.resource.should == 'invoices'
    end
  end

  describe "#self.as_resource" do
    it "Should temporarily set resource during block" do
      model = klass
      model.as_resource('test_resource') do |resource|
        resource.should == model
        resource.resource.should == 'test_resource'
      end
      model.resource.should == 'invoice'
    end
  end

  describe "#self.api_request" do
    it "Should generate post request with only the xml data" do
      url = klass.api_url
      xml = klass.build_xml('resource.operation', {'one' => 'one'})
      model = flexmock(klass)
      model.should_receive(:post_to_api).once.with(url, {:body => xml})
      klass.api_request(xml)
    end
  end

  describe '#self.build_xml' do
    let :xml_request do
      {
          :id => '1',
          :sub_item => {
              :item => 'one',
              :price => '1.0'
          }
      }
    end

    shared_examples_for "xml object" do
      subject { xml }
      it "Should give proper instruction" do
        should include('<?xml version="1.0" encoding="UTF-8"?>')
      end

      it "Should have proper method (invoice.list)" do
        should have_tag('request[method="invoice.list"]')
      end
    end

    context "When building queries" do
      let(:xml) do
        klass.build_xml('list', xml_request, :query)
      end

      subject { xml }

      it_behaves_like 'xml object'

      it "Should not have resource tag" do
        should_not have_tag 'request > resource'
      end

      it "Should use xml_request params without resource root" do
        should have_tag 'request id', '1'
        should have_tag 'request sub_item item', 'one'
        should have_tag 'request sub_item price', '1.0'
      end

    end

    context "When building objects" do
      let(:xml) do
        klass.build_xml('list', xml_request, :object)
      end

      subject { xml }

      it_behaves_like 'xml object'

      it "Should have request > invoice tag" do
        should have_tag 'request > invoice'
      end

      it "Should use xml_request params" do
        should have_tag "request invoice id", '1'
        should have_tag "request invoice sub_item item", 'one'
        should have_tag "request invoice sub_item price", '1.0'
      end
    end
  end

  describe "#self.fetch" do
    let(:params) do
      {'invoice_id' => '1'}
    end

    let(:operation) do
      'resource.method'
    end

    let(:response) do
      mock_response(fresh_sample(:invoice_response))
    end

    before(:each) do
      model = flexmock(klass)
      model.should_receive(:api_request).at_most.once.returns(response)
    end

    shared_examples_for "successful fetch" do
      it "Should return fetch results as a ApolloFresh::Collection" do
        @fetch.class.should == ApolloFresh::Collection
      end

      it "Should contain the same invoices as in sample data" do
        invoices = response['response']['invoices']['invoice']
        if(invoices.is_a?(Hash))
          invoices = [invoices]
        end
        @fetch.should == invoices
      end

      context "When fetch collection is returned" do
        before(:each) do
          @params = response['response']['invoices']
        end

        it "Should have pages param equal to invoices[pages]" do
          @fetch.params['pages'].should == @params['pages']
        end

        it "Should have page param equal to invoices[total]" do
          @fetch.params['page'].should == @params['page']
        end

        it "Should have total param equal to invoices[total]" do
          @fetch.params['total'].should == @params['total']
        end

        it "Should have per_page param eqaul to invoices[per_page]" do
          @fetch.params['per_page'].should == @params['per_page']
        end
      end
    end

    it "Should not have a loaded configuration" do
      klass.should_not have_config_loaded
    end

    it "Should load configuration on fetch if not already loaded" do
      model = flexmock(klass)
      model.should_receive(:load_config!).once()
      klass.fetch(operation, params)
    end

    it "Should have loaded configuration after first fetch" do
      klass.fetch(operation, params)
      klass.should have_config_loaded

      klass.api_key.should == 'test_key'
      klass.api_url.should == 'test'
    end

    context "When results return from an unkown resource" do
      before(:each) { klass.resource = 'unknown' }
      it "Should raise an ApolloFresh::Exception::ResponseError" do
        lambda {
          klass.fetch(operation, params)
        }.should raise_exception ApolloFresh::Exception::ResponseError
      end
    end

    context "When sending xml_type :query" do
      it "Should call build_xml with :query parameter" do
        model = flexmock(klass)
        model.should_receive(:build_xml).with(operation, params, :query)
        klass.fetch(operation, params)
      end

      context "When remote response with singular resource (get)" do
        let(:response) do
          fresh_sample(:get_response, :invoice)
        end

        before(:each) do
          model = flexmock(klass)
          model.should_receive(:api_request).returns(response)
        end

        it "Should return a single invoice as a hash" do
          params = {}
          fetch = klass.fetch('get', params)
          fetch.should == response['response']['invoice']
        end

      end

    end

    context "When sending xml_type :object" do
      it "Should call build_xml with :object parameter" do
        model = flexmock(klass)
        model.should_receive(:build_xml).with(operation, params, :object)
        klass.fetch(operation, params, :object)
      end

      context "When requesting an update method" do
        let(:response) do
          fresh_sample(:update_response, :invoice)
        end

        context "When remote returns status = ok" do
          before(:each) do
            model = flexmock(klass)
            model.should_receive(:api_request).at_most.once.returns(response)
          end

          it "Should return true" do
            fetch = klass.fetch('update', {:invoice_id => 1}, :object)
            fetch.should be_true
          end
        end

      end

      context "When requesting a create method" do
        let(:response) do
          fresh_sample(:create_response, :invoice)
        end

        context 'When remote status = success and it returns invoice_id' do
          before(:each) do
            model = flexmock(klass)
            model.should_receive(:api_request).at_most.once.returns(response)
          end

          it "Should return {invoice_id => '1'}" do
            fetch = klass.fetch('create', {:create_params => 'params'}, :object)
            fetch.should == {'invoice_id' => '1'}
          end

        end
      end

    end

    context "When response provides single objects" do
      let(:response) do
        fresh_sample(:invoice_response, 1, 5, 1)
      end

      before(:each) do
        model = flexmock(klass)
        model.should_receive(:api_request).returns(response)
        @fetch = klass.fetch(operation, params)
      end

      it_behaves_like "successful fetch"
    end

    context "When remote provides multiple objects" do
      let(:response) do
        fresh_sample(:invoice_response, 20, 5, 1)
      end

      before(:each) do
        model = flexmock(klass)
        model.should_receive(:api_request).returns(response)
        @fetch = klass.fetch(operation, params)
      end

      it_behaves_like "successful fetch"
    end

    context "When remote response with a failure" do
      let(:invalid_method_error) do
        mock_response("response" => {
          "status" => 'fail',
          "error" => "Invalid this or that..."
        })
      end

      it "Should raise ApolloFresh::Exception::ResponseError" do
        if(klass.respond_to?(:flexmock_teardown))
          klass.flexmock_teardown
        end

        model = flexmock(klass)
        model.should_receive(:api_request).once().returns(invalid_method_error)
        lambda {
          model.fetch(operation, params)
        }.should raise_error(ApolloFresh::Exception::ResponseError, "Invalid this or that...")
      end
    end
  end

  describe "#self.all" do
    it "Should all fetch('list', params, :query)" do
      params = {:param => 'one'}
      model = flexmock(klass)
      model.should_receive(:fetch).once().with('list', params, :query)
      klass.all(params)
    end
  end

  describe "#self.create" do
    it "Should call fetch('create', params, :object)" do
      params = {'create_params' => 'params'}
      model = flexmock(klass)
      model.should_receive(:fetch).once.with('create', params, :object)
      klass.create(params)
    end
  end

  describe "#self.update" do
    it "Should call fetch('update', params, :object)" do
      params = {'update_params' => 'params'}
      model = flexmock(klass)
      model.should_receive(:fetch).once.with('update', params, :object)
      klass.update(params)
    end
  end

  describe "#self.find" do
    let(:response) do
      fresh_sample(:get_response, :invoice)
    end

    before(:each) do
      model = flexmock(klass)
      model.should_receive(:api_request).returns(response)
    end

    context "When successful" do
      it "Should return hash" do
        params = {'invoice_id' => '1'}
        fetch = klass.fetch('get', params)
        fetch.should == response['response']['invoice']
      end
    end
  end


  context "#self.all!" do
    let(:page_sequence) do
      list = []
      Range.new(1, 4).each do |i|
        start_id = (i > 1)? 5 * (i - 1) : 1
        end_id = start_id + 5

        list << fresh_collection(:invoices, 20, 5, i, Range.new(start_id, end_id))
      end
      list
    end

    let(:complete_sequence) do
      complete = []
      page_sequence.each do |sequence|
        complete << sequence
      end
      complete.flatten!
      complete.index_by{ |ar| ar['invoice_id'] }
    end

    context "When testing our specifications" do
      it "Should have complete_sequence with invoice_id as index" do
        page_sequence.each do |sequence|
          sequence.each do |page|
            complete_sequence.should have_key(page['invoice_id'])
            complete_sequence[page['invoice_id']].should == page
          end
        end
      end
    end

    context "When testing in sequence" do
      before(:each) do
        model = flexmock(klass)
        page_sequence.each do |page|
          model.should_receive(:fetch).with('list', {:page => page.params['page'].to_i, :per_page => 5}, :query).returns(page).once.ordered(:paginate)
        end
      end

      it "Should return requests in sequence" do
        model = flexmock(klass)
        page_sequence.each do |page|
          model.fetch('list', {:page => page.params['page'].to_i, :per_page => 5}, :query).should == page
        end
      end      
      it "Should return all four pages as one array" do
        klass.all!(5).should == complete_sequence
      end
    end
  end
  

end
