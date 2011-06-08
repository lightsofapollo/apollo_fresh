module ApolloFresh
  module Format
    class DateComponents
      

      def initialize(record, options = {})
        @record = record
        @fields = options[:fields] || []
      end

      def format!
        @fields.each do |field|
          field = field.to_s
          if(@record.has_key?(field))
            @record[field + '_dc'] = self.class.split(@record[field])
          end
        end
        @record
      end
      
      def self.split(date)
        if(date.is_a?(String))
          date = Time.parse(date)
        elsif(date.respond_to?(:to_time))
          date = date.to_time
        end
        {
          'year' => date.year,
          'month' => date.month,
          'day' => date.day,
          'hour' => date.hour,
          'minute' => date.min,
          'tz' => date.zone
        }
      end

      def self.attached(model, options)
        fields = options[:fields] || []
        model.send(:include, Model)
        model.date_component_fields = fields
        model.date_component_fields.each do |my_field|
          model.send(:set_field, my_field.to_s + '_dc', :type => Hash)
        end
      end

      module Model
        extend ActiveSupport::Concern

        included do
          before_save :create_date_component_fields
          cattr_accessor :date_component_fields
        end

        def create_date_component_fields
          date_component_fields.each do |field|
            date = self.send(field.to_sym)
            self.send(field.to_s + '_dc=', ApolloFresh::Format::DateComponents.split(date))
          end
        end
      end

    end
  end
end