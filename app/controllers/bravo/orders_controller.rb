class Bravo::OrdersController < SubOrdersController
  layout 'bravo/application'

  before_filter :generate_password, only: :create

  def new
    @products = BravoProduct.order(:quantity).limit(50)
    @order = BravoOrder.new
  end

  def create
    @user  = User.create_with(user_params).find_or_create_by(email: user_params[:email].downcase) do |user|
      user.was_created = true
    end

    @product = BravoProduct.find_by_id(order_params[:product_id])
    promo = PromoCode.find_by_code(order_params[:promo_code])

    if @order.save

      @order = BravoOrder.new(
        user: @user,
        price: final_accessory_engraving_price(promo, order_params[:fbshare], order_params[:twshare], order_params[:engraving], order_params[:accessory_pack]),
        product: nil,
        landing_page: order_params[:subdomain],
        promo_code: order_params[:promo_code],
        ca_sales_tax: order_params[:ca_sales_tax],
        intl_shipping: order_params[:intl_shipping],
        color: nil,
        engraving: order_params[:engraving],
        accessory_pack: order_params[:accessory_pack],
        quantity: 0
      )

    else
      redirect_to :back, alert: "Please provide an email address"
    end
  end

  def confirmation
    @order = BravoOrder.find(params[:id])
    @order_params = sanitised_amazon_params(amazon_params)

    set_internal_status

    if !@order.update_attributes(@order_params) || Order::AMAZON_ERROR_STATUS.include?(amazon_params['status'])
      redirect_to new_bravo_order_path, flash: { error: "There was an error processing your payment. Please contact support@thetrackr.com" }
    else
      @order.user.credit.process if order.user.credit.present?
      send_bravo_confirmation_email(@order)
      if @order.accessory_pack  || @order.engraving
        add_profile(@order)
      end
      redirect_to bravo_order_path(@order), flash: { success: 'Your payment was successful' }
    end
  end

  def promo_code
    respond_to do |format|
      format.json do
        promo = PromoCode.find_by_code(promo_params[:code])
        product = BravoProduct.find_by_id(promo_params[:product_id])

        if promo && product
          render json: {
            price: product.final_price(
              promo,
              promo_params[:fbshare],
              promo_params[:twshare],
              promo_params[:color],
              promo_params[:engraving],
              promo_params[:accessory_pack],
              promo_params[:intl_shipping],
              promo_params[:credit]
            ),
            message: 'Success', code: promo.code, discount: promo.discount }

        elsif promo && product.nil?
          render json: {
            price: final_accessory_engraving_price(
              promo,
              promo_params[:fbshare],
              promo_params[:twshare],
              promo_params[:engraving],
              promo_params[:accessory_pack],
              promo_params[:intl_shipping]
            ),
            message: 'Success', code: promo.code, discount: promo.discount
          }
        else
          render json: { error: 'invalid code' }, status: 422
        end
      end
    end
  end

  def price
    respond_to do |format|
      format.json do
        product = BravoProduct.find_by_id(promo_params[:product_id])
        promo = PromoCode.find_by_code(promo_params[:code])

          render json: {
            price: product.final_price(
              promo,
              promo_params[:fbshare],
              promo_params[:twshare],
              promo_params[:engraving],
              promo_params[:accessory_pack],
              promo_params[:intl_shipping]
            )
          }
      end
    end
  end

  def show
    @order = Order.includes(:product).find(params[:id])
    @promo = PromoCode.find_by_code(@order.promo_code) if @order.promo_code.present?
  end

private
  def order_params
    params.permit(:email, :promo_code, :product_id, :password, :password_confirmation, :subdomain, :ca_sales_tax, :intl_shipping, :fbshare, :twshare, :accessory_pack, :engraving, :color)
  end

  def user_params
    order_params.permit(:email, :password, :password_confirmation)
  end

  def promo_params
    params.permit(:code, :product_id, :fbshare, :twshare, :color, :engraving, :accessory_pack, :intl_shipping, :credit)
  end

  def generate_password
    passwd = Devise.friendly_token.first(8)
    params.merge!(password: passwd, password_confirmation: passwd)
  end

  def send_bravo_confirmation_email(order)
    mandrill = Mandrill::API.new
    rendered = mandrill.templates.render 'Bravo Confirmation',
      [],
      [
        { name: 'user_name', content: order.user.email },
        { name: 'bravo_ref_url', content: order.user.bravo_referral_url }
      ]

    message = {
      subject: 'TrackR bravo Order Confirmation',
      to: [{ email: order.user.email }],
      from_email: 'support@thetrackr.com',
      from_name: 'The TrackR Team',
      html: rendered['html']
    }

    mandrill.messages.send(message)
  end

  def add_profile(order)
    profile = order.create_profile
    if profile.present?
      flash[:notice] = "A profile was created for your custom TrackR bravo order. Please check your email for further instructions on how to save your custom options."
      profile.send_bravo_profile_email
    end
  end
end
