require 'rubygems'
require 'spork'

Spork.prefork do
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'rspec_tag_matchers'
  require 'timecop'
end

Spork.each_run do
    # This code will be run each time you run your specs.
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
  Dir[Rails.root.join("spec/fabricators/**/*.rb")].each {|f| require f}
  Dir[Rails.root.join("spec/shared/**/*.rb")].each {|f| require f}

  RSpec.configure do |config|
    config.include(RspecTagMatchers)
    config.include Mongoid::Matchers
    config.include ApolloFresh::Spec::SampleData
    
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
    config.use_transactional_fixtures = true

    config.after(:each) do
      Mongoid.database.collections.each do |collection|
        unless collection.name =~ /^system\./
          collection.remove
        end
      end
    end
    
  end

end

# --- Instructions ---
# - Sort through your spec_helper file. Place as much environment loading 
#   code that you don't normally modify during development in the 
#   Spork.prefork block.
# - Place the rest under Spork.each_run block
# - Any code that is left outside of the blocks will be ran during preforking
#   and during each_run!
# - These instructions should self-destruct in 10 seconds.  If they don't,
#   feel free to delete them.
#




# This file is copied to spec/ when you run 'rails generate rspec:install'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.

