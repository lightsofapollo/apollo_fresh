require 'rubygems'
require 'bundler/setup'

Bundler.require :default, :test

$: << File.dirname(File.dirname(__FILE__)) + '/lib/'

require 'flexmock'
require 'rspec_tag_matchers'
require 'timecop'
require 'apollo_fresh'
require 'apollo_fresh/spec/sample_data'

APOLLO_FRESH_ROOT = File.dirname(File.dirname(__FILE__))

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}
Dir["#{File.dirname(__FILE__)}/fabricators/**/*.rb"].each {|f| require f}
Dir["#{File.dirname(__FILE__)}/shared/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.include(RspecTagMatchers)
  config.include Mongoid::Matchers
  config.include ::ApolloFresh::Spec::SampleData

  config.before(:suite) do
    Mongoid.configure do |config|
      config.master = Mongo::Connection.new.db("apollo_fresh_test")
    end
  end
  
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :flexmock

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.

  config.after(:each) do
    Mongoid.database.collections.each do |collection|
      unless collection.name =~ /^system\./
        collection.remove
      end
    end
  end
  
end
