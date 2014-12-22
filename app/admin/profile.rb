ActiveAdmin.register Profile do
  actions :all, except: [:new, :create, :destroy]
  filter :id, as: :number
  filter :order_id, as: :number
  filter :order_user_email, as: :string
  filter :created_at, as: :date_range

  controller do
    def update
      @profile = Profile.find(params[:id])
      if @profile.update_attributes(profile_params)
        redirect_to admin_profile_path(@profile), flash: {success: "Profile was successfully updated!"}
      else
        render :edit
      end
    end

    def profile_params
      params.require(:profile).permit(accessory_packs: [], engravings: [])
    end
  end

  index do
    column :id
    column :engravings do |profile|
      profile.engravings.try(:join, ',')
    end
    column :accessory_packs do |profile|
      profile.accessory_packs.try(:join, ',')
    end
    column :order
    actions
  end

  show do |profile|
    attributes_table do
      row :id
      row :user do
        profile.order.user.email
      end
      profile.engravings.each_with_index do |engraving, i|
        row "Engraving #{i+1}" do
          engraving
        end
      end
      profile.accessory_packs.each_with_index do |accessory_pack, i|
        row "Accessory Pack #{i+1}" do
          accessory_pack
        end
      end
    end
  end

  form do |f|
    f.inputs 'Profile Details' do
      if f.object.accessory_packs.any?
        packs_number = f.object.accessory_packs.size
        f.object.accessory_packs.each_with_index  do |accessory_pack, i|
          f.input :accessory_packs, :label=> "Accessory_pack #{i+1}", as: :select, collection: Profile::ACCESSORY_PACK_OPTIONS, input_html: { value: accessory_pack, name: "profile[accessory_packs][]", id: "accessory_pack_#{i+1}"}
        end
        if packs_number < 3
          (3 - packs_number).times do |i|
            f.input :accessory_packs, :label=> "Accessory_pack #{packs_number + i+1}", as: :select, collection: options_for_select(Profile::ACCESSORY_PACK_OPTIONS, Profile::ACCESSORY_PACK_OPTIONS.first), input_html: { value: "",  name: "profile[accessory_packs][]", id: "accessory_pack_#{i+1}"}
          end
        end
      else
        3.times do |i|
          f.input :accessory_packs, :label=> "Accessory_pack #{i+1}", as: :select, collection: Profile::ACCESSORY_PACK_OPTIONS, input_html: { value: Profile::ACCESSORY_PACK_OPTIONS.first, name: "profile[accessory_packs][]", id: "accessory_pack_#{i+1}"}
        end
      end
      if f.object.engravings.any?
        engravings_num = f.object.engravings.size
        empty_num = f.object.order.quantity - engravings_num
        f.object.engravings.each_with_index  do |engraving, i|
          f.input :engravings, hint: "Clear the field to remove engraving", :label=> "Engraving #{i+1}", as: :string, input_html: { value: engraving, name: "profile[engravings][]", maxlength: 17, id: "engraving_#{i+1}" }
        end
        if empty_num > 0
          empty_num.times do |i|
            f.input :engravings, hint: "Clear the field to remove engraving", :label=> "Engraving #{i+ engravings_num+1}", as: :string, input_html: { value: "", name: "profile[engravings][]", maxlength: 17, id: "engraving_#{i+1}" }
          end
        end
      else
        f.object.order.quantity.times do |i|
          f.input :engravings, hint: "Clear the field to remove engraving", :label=> "Engraving #{i+1}", as: :string, input_html: { value: "", name: "profile[engravings][]", maxlength: 17, id: "engraving_#{i+1}" }
        end
      end
    end
    f.actions
  end

  permit_params :engravings, :accessory_packs
end
