module ApolloFresh
  class Model
    class_attribute :model, :_resource, :_formatters
    self._formatters = {}

    def self.inherited(base)
      super
      ApolloFresh::Update.add_auto_update(base)
      base.send(:include, Mongoid::Document)
      base.class_eval do
        class_attribute :_child_formatters
        self._child_formatters = {}
        attach_formatter(ApolloFresh::Format::HashedArray)
      end
    end

    class << self

      def population_formatters
        results = []
        self._formatters.each do |object, options|
          results << {object => options}
        end
        if(respond_to?(:_child_formatters))
          self._child_formatters.each do |object, options|
            results << {object => options}
          end
        end
        results
      end
      
      def attach_formatter(formatter, options = {})
        unless(formatter.instance_methods.map(&:to_sym).include?(:format!))
          raise ArgumentError.new("Formatter given must provide format! instance method")
        end
        if(self == ApolloFresh::Model)
          self._formatters[formatter] = options
        else
          self._child_formatters[formatter] = options
        end
        if(formatter.respond_to?(:attached))
          formatter.attached(self, options)
        end
      end

      def remove_formatter(formatter)
        if(self == ApolloFresh::Model)
          self._formatters.delete(formatter)
        else
          if(self._formatters.has_key?(formatter))
            formatters = self._formatters.clone
            formatters.delete(formatter)
            self._formatters = formatters
          else
            self._child_formatters.delete(formatter)
          end
        end
      end

      def has_formatter?(formatter)
        if(self._formatters.has_key?(formatter))
          true
        elsif(self.respond_to?(:_child_formatters) && self._child_formatters.has_key?(formatter))
          true
        else
          false
        end
      end

      def api
        self.model = ApolloFresh::Api unless self.model
        self.model
      end

      def resource=(value)
        self._resource = value
        plural = value.to_s.pluralize
        self.key("#{value}_id")
        self._resource
      end

      def resource
        self._resource
      end

      def populate(data)
        formatters = population_formatters
        data.each do |resource_id, hash|
          formatters.each do |object|
            object.each do |formatter, options|
              formatter.new(hash, options).format!
            end
          end
          params = [
            {'_id' => resource_id},
            hash.merge({'_id' => resource_id}),
            {:upsert => true}
          ]
          collection.update(*params)
        end
      end

      def populate!
        result = self.api.as_resource(self.resource) do |query|
          begin
            all_records = query.all!
          rescue
            return false
          end
          self.delete_all
          formatters = population_formatters
          all_records.each do |id, record|
            formatters.each do |object|
              object.each do |formatter, options|
                formatter.new(record, options).format!
              end
            end
            self.create!(record)
          end
          true
        end
      end

    end
  end
end
