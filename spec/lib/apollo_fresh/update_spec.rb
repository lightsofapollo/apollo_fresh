require 'spec_helper'
require 'apollo_fresh/update'

class ApolloFresh::UpdateTestModel < ApolloFresh::Model
  
end

describe ApolloFresh::Update do

  subject { ApolloFresh::Update }

  def mock_model_all!
    flexmock(model.api, {:all! => all_invoices})
  end

  let(:all_invoices) do
    fresh_sample(:invoices, 40, 40, 1, 1..40)['invoice'].index_by {|obj| obj['invoice_id']}
  end

  let(:model) do
    ApolloFresh::UpdateTestModel
  end

  context "#auto_update?" do
    it "Should return false by default" do
      subject.auto_update?(model).should === ApolloFresh.configure.auto_update
    end
  end

  context "#add_auto_update" do
    before(:all) do
      subject.add_auto_update(model)
    end

    specify { subject.auto_update?(model).should === true }

  end

  context "#remove_auto_update" do
    before(:all) do
      subject.add_auto_update(model)
      subject.remove_auto_update(model)
    end

    specify { subject.auto_update?(model).should === false }
  end

  context "#self.update_all_models!" do

    context "When first initializing update records" do
      before do
        Timecop.freeze(30.minutes.ago) do
          subject.change_auto_update_models({model => true}) do
            subject.update_all_models!
          end
          @time = 0.minutes.ago
        end
        @status = subject.get_status(model) 

      end

      it "Should have updated records" do
        @status.updated_at.to_s.should == @time.to_s
      end

      it "Should have an update interval of 1.hour" do
        ApolloFresh.configure.update_interval.should == 1.hour
      end

      context "When updating records within the cooldown" do
        before do
          subject.change_auto_update_models({model => true}) do
            subject.update_all_models!
          end
          @new_status = subject.get_status(model)
        end

        it "Should have updated 30.minutes.ago" do
          @new_status.updated_at.to_s.should == @time.to_s
        end

      end

      context "When updating the records after the cooldown" do

        before do
          Timecop.freeze(31.minutes.from_now) do
            subject.change_auto_update_models({model => true}) do
              subject.update_all_models!
              @new_time = 0.minutes.ago
            end
          end
          @new_status = subject.get_status(model)
        end

        it "New time should be greater by a factor of 1.hour vs old time" do
          result = (@new_time > (@time + 1.hour))
          result.should === true
        end

        it "Should have been updated" do
          @new_status.updated_at.to_s.should == @new_time.to_s
        end

      end

    end

  end

  context "#self.update_model" do
    it "Should have 0 records" do
      model.count.should == 0
    end

    context "After updating" do
      before do
        mock_model_all!
        
        Timecop.freeze(30.minutes.ago) do
          subject.update_model(model)
          @time = 0.minutes.ago.to_s
        end
        
        @status = subject.get_status(model)
      end

      it "Should have been updated 30 minutes ago" do
        @status.updated_at.to_s.should == @time
      end

      it "Should not be working" do
        @status.working?.should === false
      end
      
      it "Should now have 40 records" do
        model.count.should == 40
      end
    end

    context "Should not update records when working" do

      before do
        Timecop.freeze(30.minutes.ago) do
          subject.create!(
            :model => model.name,
            :working => true,
            :progress => 50.00
          )
        end
        @update = subject.update_model(model)
        @status = subject.get_status(model)
      end

      it "Should not have been updated" do
        @update.should === false
      end

      it "Should have been updated 30 minutes ago" do
        @status.updated_at.to_s.should == 30.minutes.ago.to_s
      end

      it "Should have a progress of 50%" do
        @status.progress.should == 50.00
      end

    end

  end

  context "#self.get_status" do
    it "Will return false when no record on model" do
      subject.get_status(model).should === false
    end

    context "When record is working" do
      before do
        subject.create!(
          :model => model.name,
          :working => true,
          :progress => 50.00
        )
        @record = subject.get_status(model)
      end

      specify { @record.working.should be_true }
      specify { @record.progress.should == 50.00 }
      specify { @record.model.should == model.name }

    end

  end


end
