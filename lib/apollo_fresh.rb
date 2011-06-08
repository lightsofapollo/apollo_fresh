require 'apollo_fresh/configuration'
require 'apollo_fresh/api'

module ApolloFresh

  module_function

  def configure
    config = ApolloFresh::Configuration.instance
    (block_given?) ? yield(config) : config
  end

end
