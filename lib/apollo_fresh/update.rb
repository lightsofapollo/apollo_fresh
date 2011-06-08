module ApolloFresh
  class Update
    include Mongoid::Document
    include Mongoid::Timestamps

    field :model, :type => String
    field :working, :type => Boolean
    field :progress, :type => Float
    
    index :model, :unique => true

    class << self

      @@auto_update_models = {}

      def auto_update_models
        @@auto_update_models
      end
      
      def auto_update?(model)
        @@auto_update_models.has_key?(model)
      end

      def add_auto_update(model)
        @@auto_update_models[model] = true
      end

      def remove_auto_update(model)
        @@auto_update_models.delete(model)
      end

      def change_auto_update_models(models)
        original = @@auto_update_models.dup
        @@auto_update_models = models
        yield
        @@auto_update_models = original
      end

      def update_all_models!
        auto_update_models.each do |model, exist|
          status = get_status(model)
          if(status)
            next_update = status.updated_at + ApolloFresh.configure.update_interval
            if(Time.now >= next_update)
              update_model(model)
            end
          else
            update_model(model)
          end
        end
      end

      def update_model(object)
        unless(object.respond_to?(:populate!))
          raise("Given class must respond to populate!")
        end

        record = find_or_initialize_by(:model => object.name)
        if(record.persisted?)
          if(record.working?)
            return false
          end
        end

        record.working = true
        record.progress = 0.0
        record.save
        
        object.populate! #This could take a long... time

        record.working = false
        record.save
      end

      def get_status(model)
        record = self.where(:model => model.name).first
        if(record)
          record
        else
          false
        end
      end

      def progress(model)
        updating_model = where(:model => model.name, :working => true).first
        if(updating_model)
          updating_model.progress
        else
          false
        end
      end

      def working?(model)
        updating_model = where(:model => model.name, :working => true).first
        if(updating_model)
          true
        else
          false
        end
      end

    end

  end
end