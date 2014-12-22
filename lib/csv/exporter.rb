module Csv
  class Exporter
    attr_accessor :bravo_order_ids, :users, :serial_counter

    def initialize
      @bravo_order_ids  = collect_order_ids
      @users = collect_users
      @serial_counter = 0
    end


    def create_file
      file = CSV.generate do |csv|
        set_headings(csv)
        users.each do |user|
          add_to_file(user, csv)
        end
      end
      file
    end

    def set_sent_to_manufacturer
      orders.update_all(sent_to_manufacturer: true)
    end

    private

    def orders
      with_profiles_ids = BravoOrder.where("quantity IS NOT NULL").where("engraving='t' OR accessory_pack='t'")
                                    .where("orders.id IN (SELECT DISTINCT (bravo_order_id) FROM profiles WHERE ARRAY_LENGTH(engravings, 1) IS NOT NULL OR )")
                                    .where(sent_to_manufacturer: false)#.where(internal_status: "ready_to_be_shipped")
      without_profiles_ids = BravoOrder.where("quantity IS NOT NULL").where("(engraving='f' AND  accessory_pack='f') OR (engraving IS NULL AND accessory_pack IS NULL)").where(sent_to_manufacturer: false)#.where(internal_status: "ready_to_be_shipped")
      (with_profiles_ids + without_profiles_ids)
    end

    def collect_order_ids
      ids = orders.map(&:id)
    end

    def collect_users
      order_ids = collect_order_ids
      ids = BravoOrder.where(id: order_ids).select(:user_id).distinct.map(&:user_id)
      User.where(id: ids).includes(orders: [:profile])
    end

    def heading_1
      ["SN/Code (alphabetical)", "Order ID", "Name (alphabetical)", "Email", "Address 1", "Address 2", "City", "State", "Zip", "Country", "Engraving Letters", "Quantity", "Color","", "", "", "Accessory", "", ""]
    end

    def heading_2
      ["", "", "", "", "", "", "", "", "", "", "", "", "Silver", "Black", "Sky Blue", "Rose Gold",  "Metal Loop", "Water Proof", "Pet Collar"]
    end

    def set_headings(csv)
      csv << heading_1
      csv << heading_2
    end

    def serial(quantity)
      quantity = quantity.to_i
      if self.serial_counter == 0
        sn = quantity == 1 ? "#{self.serial_counter+1}" : "#{self.serial_counter+1} .. #{self.serial_counter + quantity}"
      else
        sn = quantity == 1 ? "#{self.serial_counter+1}" : "#{self.serial_counter+1} .. #{self.serial_counter + quantity.to_i}"
      end
      self.serial_counter = self.serial_counter + quantity.to_i
      sn
    end

    def first_info_line(item, with_email = false)
      engraving = item.first_engraving
      quantity = item.first_quantity
      colors = item.colors_quantities(quantity)
      email = with_email.present? ? item.email : ""
      accessory_packs = item.accessory_packs_quantities

      line = [
        serial(quantity),
        item.order_id,
        item.name,
        email,
        item.address_1,
        item.address_2,
        item.city,
        item.state,
        item.zip,
        item.country,
        engraving,
        quantity,
        colors[:silver],
        colors[:black],
        colors[:sky_blue],
        colors[:rose_gold],
        accessory_packs[:metal_loop],
        accessory_packs[:water_proof],
        accessory_packs[:pet_collar]
      ]
      line
    end

    def next_info_line(engraving, quantity)
      [
        serial(quantity), "", "", "", "", "", "", "", "",  "",
        engraving,
        quantity,
        "", "", "", "", "", "", ""
      ]
    end

    def no_profile_common_info_line(npc_item, with_email)
      colors = npc_item.colors_quantities
      email = with_email.present? ? item.email : ""

      line = [
        serial(quantity),
        npc_item.order_id,
        npc_item.name,
        email,
        npc_item.address_1,
        npc_item.address_2,
        npc_item.city,
        npc_item.state,
        npc_item.zip,
        npc_item.country,
        "",
        "",
        colors[:silver],
        colors[:black],
        colors[:sky_blue],
        colors[:rose_gold],
        "",
        "",
        ""
      ]
      line
    end

    def no_profile_unique_info_line(item, with_email = false)
      colors = item.colors_quantities(quantity)
      email = with_email.present? ? item.email : ""

      line = [
        serial(quantity),
        item.order_id,
        item.name,
        item.email,
        item.address_1,
        item.address_2,
        item.city,
        item.state,
        item.zip,
        item.country,
        "",
        "",
        colors[:silver],
        colors[:black],
        colors[:sky_blue],
        colors[:rose_gold],
        "",
        "",
        ""
      ]
      line
    end

    def add_no_profile_unique(unique_orders, file)
      if unique_orders.any?
        file << no_profile_unique_info_line(NoProfileItem(npo.unique_orders.first), true)
        npo.unique_orders[1..-1].each do |order|
          file << no_profile_unique_info_line(NoProfileItem(order), false)
        end
      end
    end

    def add_no_profiles_common(not_unique_orders, file)
      if not_unique_orders.any?
        npci = NoProfileCommonItem(npo.not_unique_orders)
        file << no_profile_common_info_line(npci, true)
        add_no_profile_unique(npo.unique_orders, file)
      end
    end

    def add_no_profiles(no_profile_order, file)
      npo = NoProfileOrders.new(no_profile_orders)
      if npo.not_unique_orders.any?
        add_no_profiles_common(npo.not_unique_orders)
        add_no_profile_unique(npo.unique_orders)
      else
        add_no_profile_unique(npo.unique_orders)
      end
    end

    def add_with_profiles(with_profile_orders, file, with_email = false)
      with_profile_orders.each do |order|
        with_prof_item = WithProfileItem.new(order)
        file << first_info_line(with_prof_item, with_email)
        with_prof_item.engravings_quantities_except_first.each do |key, val|
          next_info_line(key, val)
        end
      end
    end

    def add_to_file(user, file)
      eu = ExportUser.new(user)
      if eu.no_profile_orders.any?
        add_no_profiles(eu.no_profile_orders, file)
        add_with_profiles(eu.with_profile_orders, file, false)
      else
        if eu.with_profile_orders.any?
          add_with_profiles(eu.with_profile_orders, file, true)
        end
      end
    end
  end
end
