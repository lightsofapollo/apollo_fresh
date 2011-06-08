module ApolloFresh
  class Configuration
    include Singleton

    attr_accessor :auto_update, :update_interval

    def update_interval
      @update_interval ||= 1.hour
    end

    def auto_update
      (@auto_update.nil?) ? @auto_update = true : @auto_update
    end

    def auto_update?
      !!auto_update
    end

  end
end