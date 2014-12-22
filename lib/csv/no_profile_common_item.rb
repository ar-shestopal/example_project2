module Csv
  class NoProfileItem < Item
    attr_reader :order

    def initialize(order)
      @order = order
    end

  end
end
