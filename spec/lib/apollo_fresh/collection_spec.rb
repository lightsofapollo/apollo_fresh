require 'spec_helper'

describe ApolloFresh::Collection do

  it "Should behave like an array because it is descended from an Array" do
    array = ['one', 'two', 'three']
    collection = ApolloFresh::Collection.new(array, {})
    collection.should == array
  end

  describe "#params" do
    it "Should return params (hash) from new" do
      params = {:param => :value, :other_param => :value}
      collection = ApolloFresh::Collection.new([], params)
      collection.params.should == params
    end
  end

  it "Should inherit from WillPaginate::Collection" do
    ApolloFresh::Collection.ancestors.should include WillPaginate::Collection
  end

  context "When collection is create via .new with pagination params" do
    let(:collection) do
      ApolloFresh::Collection.new(
        [1, 2, 3, 4, 5],
        {
          'per_page' => '5',
          'pages' => '4',
          'total' => '20',
          'page' => '2'
        }
      )
    end

    it "Should have set current_page" do
      collection.current_page.should == 2
    end

    it "Should have per_page set" do
      collection.per_page.should == 5
    end

    it "Should have total_pages set" do
      collection.total_pages.should == 4
    end

    it "Should have total_entries set" do
      collection.total_entries.should == 20
    end

  end

end