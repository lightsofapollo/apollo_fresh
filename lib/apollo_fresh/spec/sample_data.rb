module ApolloFresh
  module Spec
    module SampleData
      def fresh_mock_fetch(result, operation, params, xml_type = :query)
        ApolloFresh::Api.expects(:fetch).with(operation, params, xml_type).returns(result)
        params
      end

      def fresh_sample(sample, *args)
        Data.send(sample, *args)
      end

      def fresh_collection(sample_name, *args)
        sample = fresh_sample(sample_name, *args)
        singular = sample_name.to_s.singularize
        collection_data = sample.delete(singular)
        ApolloFresh::Collection.new(collection_data, sample)
      end

      module Data
        module_function

        def line_item()
          {
              "name"        =>nil,
              "unit_cost"   =>"90.00000000",
              "quantity"    =>"1.00000000",
              "tax1_percent"=>"0.0000",
              "amount"      =>"90.000",
              "tax2_percent"=>"0.0000",
              "tax2_name"   =>nil,
              "line_id"     =>"1",
              "tax1_name"   =>nil,
              "type"        =>"Item",
              "description" =>"Hotfix so server was up during the holiday"
          }
        end

        def lines()
          {'line' => [
              line_item,
              line_item,
              line_item
          ]}
        end

        def invoice(invoice_id = nil)
          {
              "number"            =>"0000046",
              "vat_number"        =>nil,
              "lines"             => lines,
              "discount"          =>"0.0000",
              "p_street1"         =>nil,
              "paid"              =>"0.000",
              "notes"             =>"Billed at off hour rate of $90/hr.\r\nHours worked during 12/24/2010",
              "vat_name"          =>nil,
              "folder"            =>"active",
              "invoice_id"        => invoice_id || "00000000046",
              "p_street2"         =>nil,
              "p_city"            =>nil,
              "p_state"           =>nil,
              "amount"            =>"90.000",
              "url"               =>"https://lightsofapollo.freshbooks.com/view/DP6EZKEUvWYY9c3",
              "language"          =>"en",
              "date"              =>"2010-12-24",
              "client_id"         =>"10",
              "p_code"            =>nil,
              "auth_url"          =>"https://lightsofapollo.freshbooks.com/invoices/00000000046",
              "last_name"         =>nil,
              "links"             =>{
                  "edit"       =>"https://lightsofapollo.freshbooks.com/invoices/00000000046/edit",
                  "client_view"=>"https://lightsofapollo.freshbooks.com/view/DP6EZKEUvWYY9c3",
                  "view"       =>"https://lightsofapollo.freshbooks.com/invoices/00000000046"
              },
              "organization"      =>"7d7d.com",
              "amount_outstanding"=>"90",
              "recurring_id"      =>nil,
              "p_country"         =>nil,
              "po_number"         =>nil,
              "status"            =>"draft",
              "terms"             =>"Pay to the order of:\r\nSahaja James Lal\r\nAddress:\r\n21175 NW Galice Lane\r\nApt 105\r\nPortland, OR \r\n97229",
              "return_uri"        =>nil,
              "updated"           =>"2010-12-24 15:17:18",
              "currency_code"     =>"USD",
              "first_name"        =>nil
          }
        end

        def invoices(total = 20, per_page = 5, page = 1, range = nil)
          number_of_invoices = (total < per_page)? total : per_page
          invoice_list = []
          (number_of_invoices).times do
            if(range.is_a?(Range))
              range = range.to_a.collect{|s| s.to_s }
            end
            if(range)
              invoice_list << invoice(range.shift)
            else
              invoice_list << invoice
            end
          end
          if(invoice_list.count == 1)
            invoice_list = invoice_list.pop
          end
          paginated({'invoice' => invoice_list}, total, per_page, page)
        end

        def invoice_response(total = 20, per_page = 5, page = 1)
          response('invoices' => invoices(total, per_page, page))
        end

        def get_response(type)
          object = send(type)
          response({type.to_s => object})
        end

        def update_response(*args)
          response({'invoice' => invoice})
        end

        def create_response(type)
          type_id = type.to_s + '_id'
          type_value = '1'
          response({type_id => type_value})
        end

        def paginated(hash, total, per_page, page)
          pages = (total / per_page).ceil
          pages = 1 if pages < 1
          {
              'total' => total.to_s,
              'pages' => pages.to_s,
              'per_page' => per_page.to_s,
              'page' => page.to_s
          }.merge(hash)
        end

        def response(hash = {})
          {
              'response' => {
                  'status' => 'ok',
                  'xmlns' => "http://www.freshbooks.com/api/"
              }.merge(hash)
          }
        end

      end

    end
  end
end