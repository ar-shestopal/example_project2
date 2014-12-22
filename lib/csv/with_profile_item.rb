module Csv
  class WithProfileItem < Item
    attr_reader :order

    def initialize(order)
      @order = order
    end

    def engravings
      order.try(:profile).try(:engravings) || []
    end

    def uniq_engravings
      engravings.try(:uniq)
    end

    def engravings_quantities
      result = {}
      if engravings.any?
        uniq_engravings.each do |uniq_engr|
          count = 0
          engravings.each do |engr|
            if engr == uniq_engr
              count += 1
            end
          end
          result[uniq_engr] = count.to_s
        end
      end
      result
    end

    def first_engraving
      engravings_quantities.first.try(:first) || ""
    end

    def first_quantity
      engravings_quantities.first.try(:last).try(:to_s) || order.quantity.to_s
    end

    def engravings_quantities_except_first
      engravings = engravings_quantities
      engravings.shift
      engravings
    end

    def accessory_packs
      order.try(:profile).try(:accessory_packs) || []
    end

    def uniq_accessory_packs
      accessory_packs.uniq
    end

    def accessory_packs_hash
      result = {}
      if accessory_packs.any?
        accessory_packs = self.accessory_packs
        uniq_accessory_packs.each do |uniq_pack|
          count = 0
          accessory_packs.each do |pack|
            if pack == uniq_pack
              count += 1
            end
          end
          result[uniq_pack] = count.to_s
        end
      end
      result
    end


    def accessory_packs_quantities
      result = {}
      result[:metal_loop] = accessory_packs_hash["Metal Loop"].to_s
      result[:water_proof] = accessory_packs_hash["Water Proof"].to_s
      result[:pet_collar] = accessory_packs_hash["Pet Collar"].to_s
      result
    end
  end
end
