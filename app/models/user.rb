require 'mandrill'

class User < ActiveRecord::Base
  VALID_DEVICES = %w(apple android other)
  VALID_PURCHASED_DEVICES = ['StickNFind', 'Tile', 'Zomm', 'ClickNDig', 'Cobra Tag', 'TrackR', 'inSite', 'Other']

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :orders, dependent: :destroy
  has_one :shipping_address, dependent: :destroy
  accepts_nested_attributes_for :shipping_address

  attr_accessor :referer

  before_validation :generate_ref_code

  after_save :update_user_orders_group_id, if: Proc.new{ |u| u.group_id != u.group_id_was }

  scope :still_in_queue, -> { where(giveaway_shipped: false) }

  def self.exists_on_trackr?(email)
    exists?(["email = ? AND auth_token IS NOT NULL", email])
  end

  def first_name
    self.full_name.split(" ")[0]
  end

  def send_welcome_email
    mandrill = Mandrill::API.new
    rendered = mandrill.templates.render 'Email Sign Up + Boarding Group 4',
      [],
      [
        {name: 'user_name', content: self.first_name },
        {name: 'user_referal', content: Rails.application.routes.url_helpers.root_url(ref: self.ref_code)},
        {name: 'people_ahead', content: Group.rank(self) },
        {name: 'confirmation_page_url', content: Rails.application.routes.url_helpers.profile_url(auth_token: self.auth_token)},
        {name: 'root_url', content: Rails.application.routes.url_helpers.root_url }
      ]

    message = {
      subject: 'Welcome to the TrackR Network & Boarding Group 4',
      to: [{ email: self.email }],
      from_email: 'support@thetrackr.com',
      from_name: 'Melina from TrackR',
      html: rendered['html']
    }

    mandrill.messages.send(message)
  end

  def record_kissmetrics
    KMTS.record(self.email, 'New Sign Up', { date: self.created_at, referer: User.find_by_ref_code(self.referer).try(:email) })
  end

  def bravo_referral_url
    Rails.application.routes.url_helpers.bravo_checkout_url(ref_code: self.ref_code)
  end

private
  def generate_ref_code
    self.ref_code = RefCode.generate unless self.ref_code.present?
  end

  def generate_auth_token
    begin
      self.auth_token = Devise.friendly_token
    end while User.exists?(auth_token: self.auth_token)
  end

  def set_reminder_date
    self.reminder_date = 3.days.from_now
  end

  def set_group_joined_at
    self.group_joined_at = self.created_at
  end

  def update_user_orders_group_id
    self.orders.trackr_orders.each do |order|
      order.update_column(:group_id, self.group_id)
    end
  end
end
