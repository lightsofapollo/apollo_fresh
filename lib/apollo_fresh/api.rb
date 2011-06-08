module ApolloFresh
  class Api
    include HTTParty
    class_attribute :api_key, :api_url, :resource, :_config_file, :loaded_config_file

    PAGINATION_PARAMS = ['per_page', 'pages', 'page', 'total']

    # Class Methods
    class << self      
      def as_resource(resource, &block)
        original_resource = self.resource
        self.resource = resource
        result = yield self
        self.resource = original_resource
        result
      end

      # If is nil in child will descend into parents until a non nil value or use config/freshbooks.yml
      def config_file
        config = self._config_file
        if config.nil?
          if(self == ApolloFresh::Api)
            config = Rails.root.join('config', 'freshbooks.yml')
          else
            config = self.superclass.config_file
          end
        end
        config
      end

      def config_file=(value)
        self._config_file=(value)
      end

      def has_config_loaded?
        (loaded_config_file && config_file == loaded_config_file)
      end

      def load_config!
        self.loaded_config_file = config_file
        config = YAML.load_file(config_file)[Rails.env]
        config.each do |key, value|
          self.send("#{key}=", value)
        end
        authenticate!
      end

      def authenticate!
        basic_auth(self.api_key, 'X')
      end

      # Call Freshbook API and paginate through entire set
      # Returns entire set grouped by #{self.resource}_id
      def all!(per_page = 100)
        complete_list = []
        current_page = 1
        
        collection = all(:page => current_page, :per_page => per_page)
        current_page += 1
        complete_list << collection
        params = collection.params
        
        pages = params['pages'].to_i

        while(current_page <= pages)
          complete_list << self.all(:page => current_page, :per_page => per_page)
          current_page += 1
        end
        
        complete_list.flatten!
        complete_list.index_by {|object| object["#{self.resource}_id"]}
      end

      def all(params = {})
        fetch('list', params, :query)
      end

      def create(params)
        fetch('create', params, :object)
      end

      def update(params)
        fetch('update', params, :object)
      end

      alias_method :post_to_api, :post

      def api_request(xml)
        self.post_to_api(self.api_url, :body => xml)
      end

      def fetch(method, params, xml_type = :query)
        load_config! unless has_config_loaded?

        request_xml = build_xml(method, params, xml_type)
        original_response = self.api_request(request_xml)

        Rails.logger.debug(original_response)

        response = original_response['response']
        if(response['status'] == 'fail')
          raise ApolloFresh::Exception::ResponseError.new(response['error'])
        end

        if(xml_type == :query)
          plural_resource = resource.pluralize
          singular_resource = resource
          
          unless(response.has_key?(plural_resource) || response.has_key?(singular_resource))
            Rails.logger.error original_response.inspect
            raise(ApolloFresh::Exception::ResponseError.new(
                      "Result did not contain expected resource #{plural_resource} or #{singular_resource} in result."
            ));
          end

          if(response.has_key?(plural_resource))
            results = response[plural_resource]
            pagination_params = {}
            PAGINATION_PARAMS.each do |param|
              if(response[plural_resource].has_key?(param))
                pagination_params[param] = response[plural_resource][param]
              end
            end
            results = results[resource]
            if(results.is_a?(Hash))
              results = [results]
            end
            ApolloFresh::Collection.new(results, params.merge(pagination_params))
          elsif(response.has_key?(singular_resource))
            response[singular_resource]
          end
          
        elsif(xml_type == :object)
          id_field = self.resource.to_s + '_id'
          if(response.has_key?(id_field))
            return {id_field => response[id_field]}
          else
            #We can safely return because the terms for success on an update are only
            #A status = ok, there are possible failures with this method if
            #The API returns an #{resource}_id that is not expected
            return true
          end
        else
          original_response
        end
      end

      def build_xml(method, params, type = :query)
        require 'active_support/builder' unless defined?(Builder)

        unless method.include?('.')
          method = resource.to_s + '.' + method.to_s
        end
        
        options = {
            :indent => 2,
            :root => 'request',
            :camelize => false,
            :dasherize => false
        }
        
        options[:builder] = builder = Builder::XmlMarkup.new(:indent => options[:indent])
        builder.instruct!

        build_params = lambda do
          params.each do |key ,value |
            ActiveSupport::XmlMini.to_tag(key, value, options)
          end
        end
        builder.tag!('request', {:method => method.to_s}) do
          if(type == :object)
            builder.tag!(self.resource) do
              build_params.call()
            end
          else
            build_params.call()
          end
        end
      end
    end    

  end
end