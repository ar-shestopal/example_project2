module Csv
  class ExportUser
    attr_reader :user, :with_profile_orders, :no_profile_orders

    def initialize(user)
      @user = user
      @with_profile_orders = with_profile_orders
      @no_profile_orders = no_profile_orders
    end

    def with_profile_orders
      self.user.orders.where(with_profile_conditions)
    end

    def no_profile_orders
      self.user.orders.where(no_profile_conditions)
    end

    def with_profile_conditions
      line = <<-SQL
        "orders"."type" IN ('BravoOrder') AND (quantity IS NOT NULL) AND (engraving='t' OR accessory_pack='t')
        AND (orders.id IN (SELECT DISTINCT (bravo_order_id) FROM profiles WHERE ARRAY_LENGTH(engravings, 1) IS NOT NULL
        OR ARRAY_LENGTH(accessory_packs, 1) IS NOT NULL))
      SQL
    end

    def no_profile_conditions
      line = <<-SQL
        "orders"."type" IN ('BravoOrder') AND (quantity IS NOT NULL) AND ((engraving='f' AND accessory_pack='f') OR (engraving IS NULL AND accessory_pack IS NULL))
      SQL
    end

  end
end
