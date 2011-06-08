require 'spec_helper'

describe ApolloFresh::Configuration do

  subject { ApolloFresh::Configuration }

  let!(:config) do
    subject.instance
  end

  context "#update_interval" do
    it "Should == 1.hour" do
      config.update_interval.should == 1.hour
    end
  end

  context "#auto_update?" do
    before do
      config.auto_update = true
    end

    specify { config.auto_update?.should === true }    

    context "When false" do
      before do
        @original = config.auto_update
        config.auto_update = false
      end

      after do
        config.auto_update = @original
      end

      it "Should be ahppy" do
        #raise([config, config.auto_update].inspect)
      end

      specify { config.auto_update.should === false }
      specify { config.auto_update?.should === false }

    end

  end

end