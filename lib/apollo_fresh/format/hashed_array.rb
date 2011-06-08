module ApolloFresh
  module Format
    class HashedArray

      def initialize(record, options = {})
        @record = record
        @options = options
      end

      def format!
        @record.each do |key, value|
          if(value.is_a?(Hash) && value.values.length == 1 && value.values.first.is_a?(Array))
            @record[key] = value.values.first
          end
        end
        @record
      end

    end
  end
end