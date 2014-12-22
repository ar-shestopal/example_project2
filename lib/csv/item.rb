module Csv
  class Item
    attr_reader :order

    def initialize(order)
      @order = order
    end

    def order_id
      order.id.to_s
    end

    def name
      order.address_name.to_s
    end

    def email
      order.user.email.to_s
    end

    def address_1
      order.address_line_1.to_s
    end

    def address_2
      order.address_line_2.to_s
    end

    def city
      order.city.to_s
    end

    def state
      order.city.to_s
    end

    def zip
      order.zip.to_s
    end

    def country
      order.country.to_s
    end

    def color
      order.color.to_s
    end

    def colors_quantities
      result = {}
      result[:silver] = color == "silver" ? quantity.to_s : ""
      result[:black] = color == "black" ? quantity.to_s : ""
      result[:sky_blue] = color == "sky blue" ? quantity.to_s : ""
      result[:rose_gold] = color == "rose gold" ? quantity.to_s : ""
      result
    end
  end
end
