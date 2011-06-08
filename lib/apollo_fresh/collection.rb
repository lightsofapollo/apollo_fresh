require 'will_paginate/collection'

module ApolloFresh
  class Collection < WillPaginate::Collection

    attr_reader :params

    def initialize(array, params = {})
      unless(params.is_a?(Hash))
        raise(ArgumentError.new("Second parameter (params) must pass hash"))
      end
      @params = params
      page = params['page'] || 1
      per_page = params['per_page'] || 25
      total = params['total'] || 1

      super(page, per_page, total)
      
      replace(array || [])
    end

  end
end
