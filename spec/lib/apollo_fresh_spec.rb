require 'spec_helper'

describe ApolloFresh do

  context "#configure" do
    before do
      @inner = nil

      ApolloFresh.configure do |config|
        @inner = config
      end

    end

    it "Should be an instance of ApolloFresh::Configuration" do
      @inner.class.should == ApolloFresh::Configuration
    end

    context "when no block is given" do
      it "Should return an instance of ApolloFresh::Configuration" do
        ApolloFresh.configure.instance_of?(ApolloFresh::Configuration)
      end
    end



  end

end