module ProductMacros
  EMAIL = "alexde.amazon@gmail.com"
  PASSWORD = "34834amazon"
  def wait(n = 20)
    now = Time.now
    loop do
      break if Time.now > now + n.seconds
    end
  end

  def visit_new_bravo_order
    #switch_to_subdomain("bravo")
    visit bravo_order_path(BravoOrder.first)
  end

  def go_to_bravo
    #switch_to_subdomain("bravo")
    visit bravo_root_path
  end

  def go_to_checkout
    find("a.buybutton1").click
  end

  def create_user
    User.create(email: EMAIL ,password: PASSWORD, password_confirmation: PASSWORD)
  end

  def select_bravo_product(product_id)
    find("div[data-product-id='#{product_id}']").click
    fill_in("email", with: EMAIL)
    check("engraving")
    load_amazon_config
    click_button "checkout"
  end

  def pass_amazon
    fill_in "ap_email", with: EMAIL
    fill_in "ap_password", with: PASSWORD
    click_button("signInSubmit")
    first('input[src="../pages/img/US/ship-to-this-address.gif"]').click
    select("Visa", from: "creditCardIssuer")
    find('input[name="addCreditCardNumber"]').set("1234123412341234")
    find('input[name="creditCardHolderName"]').set("Alex")
    within('select[name="expiryYear"]')do
      find("option[value='2033']").click
    end
    find('input.continue').click
    first('input[src="../pages/img/US/use-this-address.gif"]').click
  end

  def buy_bravo_product(product_id)
    go_to_bravo
    go_to_checkout
    select_bravo_product(product_id)
    pass_amazon
  end

  def load_amazon_config
    config = YAML.load_file("#{Rails.root}/config/application.yml")
    AmazonFlexPay.access_key = config["AMAZON_ACCESS_KEY"]
    AmazonFlexPay.secret_key = config["AMAZON_SECRET_KEY"]
    Capybara.app_host = 'http://www.amazon.com'
  end
end
