require 'rails_helper'

feature "Profiles", :type => :feature do
  background do
    @bravo_product = BravoProduct.create(
      title: "1 - Device Pack",
      description: "BravoTrackr - 1 Device Pack",
      price: 20,
      shipping_price: 0,
      quantity: 1
    )
    @user = create_user
    @product_id = BravoProduct.order(:quantity).first.id
  end

  scenario "buy bravo", js: true do
    go_to_bravo
    go_to_checkout
    buy_bravo_product(@product_id)
    expect(Profile.count).to eq 1
  end

  scenario "update profile", js: true do
    order = BravoOrder.create(user: @user, price: 0.0)
    profile = Profile.create(accessory_packs: ["Metal Loop", "Water Proof"], engravings: ["first", "second"], bravo_order: order, saved: true)

    create_admin_user
    login
    go_to_profile_edit
    fill_in "engraving_1", with: "new first"
    select "Pet Collar", from: "accessory_pack_1"
    click_button "Update Profile"
    wait 5
    expect(page).to have_content "Profile was successfully updated!"
    expect(Profile.find(profile.id).engravings.first).to eq "new first"
    expect(Profile.find(profile.id).accessory_packs.first).to eq "Pet Collar"
    expect(Profile.find(profile.id).saved).to be_truthy
  end
end
