require 'spec_helper'

describe ApolloFresh::Spec::SampleData do

  shared_examples_for "successful response" do
    it "Should have response[status] = ok" do
      response['response']['status'].should == 'ok'
    end
  end

  describe "#apollo_sample" do
    context "When getting line_item sample" do
      it "Should return sample data from ApolloFresh::Spec::SampleData::Data" do
        fresh_sample(:line_item).should == ApolloFresh::Spec::SampleData::Data.line_item
      end
    end

    context "When getting lines sample" do
      it "Should return sample data from ApolloFresh::Spec::SampleData::Data" do
        fresh_sample(:lines).should == ApolloFresh::Spec::SampleData::Data.lines
      end

      it "Should contain at least one entry from line_item" do
        fresh_sample(:lines)['line'].should include(ApolloFresh::Spec::SampleData::Data.line_item)
      end

    end

    context "When getting sample invoice" do
      it "Should return sample data from ApolloFresh::Spec::SampleData::Data" do
        fresh_sample(:invoice).should == ApolloFresh::Spec::SampleData::Data.invoice
      end

      it "Should use first param if available for invoice_id" do
        invoice = fresh_sample(:invoice, '1')
        invoice['invoice_id'].should == '1'
      end

      it "Should have lines key equal to lines sample data" do
        fresh_sample(:invoice)['lines'].should == ApolloFresh::Spec::SampleData::Data.lines
      end
    end

    context "When getting sample invoices" do
      context "When one invoice is returned" do
        let(:invoices) do
          #Total of one, 5 per page, page 1
          fresh_sample(:invoices, 1, 5, 1)
        end

        it "Should return invoices as a hash" do
          invoices['invoice'].should be_kind_of Hash
        end

        it "Should have invoices element equal to sample data" do
          invoices['invoice'].should == fresh_sample(:invoice)
        end

        it "Should have total of one" do
          invoices['total'].should == '1'
        end

        it "Should have 5 per page" do
          invoices['per_page'].should == '5'
        end

        it "Should be on page 1" do
          invoices['page'].should == '1'
        end

        it "Should have pages set to one" do
          invoices['pages'].should == '1'
        end
      end

      context "When multiple invoices are returned" do
        let(:invoices) do
          #Total of 20, 5 per page, page 2, 4 pages
          fresh_sample(:invoices, 20, 5, 2)
        end

        it "Should return invoices as a Array" do
          invoices['invoice'].should be_kind_of Array
        end

        it "Should have invoices element that include invoice sample data" do
          invoices['invoice'].should include(fresh_sample(:invoice))
        end

        it "Should have total of 20" do
          invoices['total'].should == '20'
        end

        it "Should have 5 per page" do
          invoices['per_page'].should == '5'
        end

        it "Should be on page 2" do
          invoices['page'].should == '2'
        end

        it "Should have pages set to four" do
          invoices['pages'].should == '4'
        end

        context "When invoice_id range is an Array" do
          let(:invoices) do
            #Total of 20, 5 per page, page 2, 4 pages, range 1-5
            fresh_sample(:invoices, 20, 5, 2, ['1', '2', '3', '4', '5'])
          end

          it "Should return invoice_id's in order" do
            range = ['1', '2', '3', '4', '5']
            invoices['invoice'].each do |invoice|
              invoice['invoice_id'].should == range.shift
            end 
          end

        end

        context "When invoice_id range is a Range" do
          let(:invoices) do
            #Total of 20, 5 per page, page 2, 4 pages, range 1-5
            fresh_sample(:invoices, 20, 5, 2, 1..5)
          end

          it "Should return invoice_id's in order" do
            range = ['1', '2', '3', '4', '5']
            invoices['invoice'].each do |invoice|
              invoice['invoice_id'].should == range.shift
            end
          end
        end

      end
    end

    context "When getting sample invoice response" do
      let :invoice_response do
        fresh_sample(:invoice_response)
      end

      it "Should return sample data from ApolloFresh::Spec::SampleData::Data" do
        invoice_response.should == ApolloFresh::Spec::SampleData::Data.invoice_response
      end

      it "Should be wrapped in response hash" do
        invoice_response.should have_key('response')
      end

      it "Should have status as ok" do
        invoice_response['response']['status'].should == 'ok'
      end

      it "Should have xmlns as http://www.freshbooks.com/api/" do
        invoice_response['response']['xmlns'].should == 'http://www.freshbooks.com/api/'
      end

      it "Should return response[invoices] as in sample data" do
        invoice_response['response']['invoices'].should == fresh_sample(:invoices)
      end

      context "When getting get response" do
        let(:response) do
          fresh_sample(:get_response, :invoice)
        end
        it_behaves_like 'successful response'

        it "Should have invoice element equal to sample data" do
          response['response']['invoice'].should == fresh_sample(:invoice)
        end

      end

      context "When getting successful create response" do
        let(:response) do
          fresh_sample(:create_response, :invoice)
        end

        it_behaves_like 'successful response'

        it "Should have invoice_id" do
          response['response'].should have_key('invoice_id')
        end
      end

      context "When getting successful update response" do
        let(:response) do
          fresh_sample(:update_response, :invoice)
        end

        it_behaves_like 'successful response'

        it "Should not contain any invoice_id element" do
          response['response'].should_not have_key('invoice_id')
        end

      end

    end

  end

  context "#fresh_collection" do
    it "Should call fresh_sample based on first argument" do
      mock = flexmock(self)
      mock.should_receive(:fresh_sample).with(:invoices).returns(ApolloFresh::Spec::SampleData::Data.invoices)
      mock.fresh_collection(:invoices)
    end

    it "Should create collection based on sample data" do
      collection = fresh_collection(:invoices, 20, 5, 2)
      params = {
          'total' => '20',
          'per_page' => '5',
          'page' => '2',
          'pages' => '4'
      }
      collection.params.should == params
      collection.should == fresh_sample(:invoices, 20, 5, 2)['invoice']
    end

  end

end