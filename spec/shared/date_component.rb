shared_examples_for "a single date component field" do |field|
  it "and should have set #{field}_dc to a hash with date components" do
    record.send(dc_field).should == date_components(record.send(field))
  end
end

shared_examples_for "date component fields" do |type, fields|

  def date_components(date)
    {
      'year' => date.year,
      'month' => date.month,
      'day' => date.day,
      'hour' => date.hour,
      'minute' => date.min,
      'tz' => date.zone
    }
  end

  fields.each do |field|

    let(:date) do
      DateTime.now
    end

    let(:time) do
      Time.now
    end

    let(:string) do
      DateTime.now
    end

    let!(:dc_field) do
      field.to_s + '_dc'
    end

    let(:setter) do
      (field.to_s + '=').to_sym 
    end

    context "When #{field} is given a string" do

      let(:record) do
        Fabricate(type, field => string)
      end

      it_behaves_like "a single date component field", field
      
    end

    context "When #{field} is given a DateTime" do
      let(:record) do
        Fabricate(type, field => date)
      end

      it_behaves_like "a single date component field", field
    end

    context "When #{field} is given a Time" do
      let(:record) do
        Fabricate(type, field => time)
      end

      it_behaves_like "a single date component field", field
    end

  end
end