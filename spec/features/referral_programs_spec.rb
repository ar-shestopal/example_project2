require 'rails_helper'

feature "ReferralPrograms", :type => :feature do
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
    create_admin_user
  end

  scenario "create program", js: true do
    login
    create_program
    expect(ReferralProgram.count).to eq 1
  end

  scenario "choose program", js: true do
    login
    create_program
    buy_bravo_product(@bravo_product.id)
    click_button "Select"
    expect(page).to have_content(ReferralProgram.first.link)
    expect(Assignment.count).to eq 1
    expect(Assignment.first.user.email).to eq ProductMacros::EMAIL
  end

  scenario "visit referral program link" do
    user = User.create(email: "test@mail.com", password: "password", password_confirmation: "password")
    program = ReferralProgram.create(number_of_friends: 2, prize: "1 TrackR bravo steel", action: "Refer a friend to view page", site: "TrackR bravo", product_type: "bravo", link: "http://localhost:9887")
    assignment = Assignment.create(user: user, referral_program: program)
    browser = Capybara.current_session.driver.browser

    visit program.referral_url(assignment.id, user.ref_code)
    visit program.referral_url(assignment.id, user.ref_code)
    already_visited_assignment = Assignment.find(assignment.id)

    expect(already_visited_assignment.number_of_referrals).not_to eq 2
    expect(already_visited_assignment.number_of_referrals).to eq 1
    expect(already_visited_assignment.is_completed).not_to be_truthy

    browser.clear_cookies
    visit program.referral_url(assignment.id, user.ref_code)
    browser.clear_cookies
    visit program.referral_url(assignment.id, user.ref_code)


    updated_assignment = Assignment.find(assignment.id)
    expect(updated_assignment.number_of_referrals).to eq 2
    expect(updated_assignment.is_completed).to be_truthy
  end
end
