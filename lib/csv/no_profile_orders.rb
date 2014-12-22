module Csv
  class NoProfileOrders
    attr_reader :orders

    def initialize(orders)
      @orders = orders
    end

    def unique_orders
      arr = self.orders
      while i < arr.size
        j = i +  1
        while j < arr.size
          if arr[i] == arr[j]
            arr[i] = nill
          end
          j += 1
        end
        i += 1
      end
      arr.uniq
    end

    def not_unique_orders
      unique_ids = unique_orders.map(&:id)
      orders = self.orders
      orders.delete_if {|o| unique_ids.include?(o.id)}
    end

    def not_unique_colors_quantities
      orders = not_unique
      result = {}
      orders.each do |o|
        result[:silver] =  result[:silver] += o.try(:quantity) if o.color == "silver"
        result[:black] =  result[:black] += o.try(:quantity) if o.color == "black"
        result[:sky_blue] =  result[:sky_blue] += o.try(:quantity) if o.color == "sky_blue"
        result[:rose_gold] =  result[:rose_gold] += o.try(:quantity) if o.color == "rose_gold"
      end
      result
    end
  end
end
