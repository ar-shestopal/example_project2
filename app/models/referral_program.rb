class ReferralProgram < ActiveRecord::Base
  #
  #has many users through Assingment model
  #Assignment
  # id: integer,
  # user_id: integer,
  # referral_program_id: integer,
  #number_of_referrals:integer - number of people who followed referral url
  #is_completed: boolean - true if user completed referral_program action
  # Assignment belongs_to_many users so it is bidirectional connection
  #

  has_many :assignments
  has_many :users, through: :assignments

  BRAVO_PRIZES = {
                   bravo_steel:                   "1 TrackR bravo steel",
                   bravo_black:                   "1 TrackR bravo black",
                   bravo_rose_gold:               "1 TrackR bravo rose gold",
                   bravo_sky_blue:                "1 TrackR bravo sky blue",
                   bravo_steel_engrav:            "1 TrackR bravo steel w/ engraving",
                   bravo_black_engrav:            "1 TrackR bravo black w/ engraving",
                   bravo_rose_gold_engrav:        "1 TrackR bravo rose gold w/ engraving",
                   bravo_sky_blue_engrav:         "1 TrackR bravo sky blue w/ engraving",
                   bravo_steel_access:            "1 TrackR bravo steel w/ accessory pack",
                   bravo_black_access:            "1 TrackR bravo black w/ accessory pack",
                   bravo_rose_gold_access:        "1 TrackR bravo rose gold w/ accessory pack",
                   bravo_sky_blue_access:         "1 TrackR bravo sky blue w/ accessory pack",
                   bravo_steel_access_engrav:     "1 TrackR bravo steel w/ accessory pack w/ engraving",
                   bravo_black_access_engrav:     "1 TrackR bravo black w/ accessory pack w/ engraving",
                   bravo_rose_gold_access_engrav: "1 TrackR bravo rose gold w/ accessory pack w/ engraving",
                   bravo_sky_blue_access_engrav:  "1 TrackR bravo sky blue w/ accessory pack w/ engraving",
                 }
  STICKR_PRIZES = { stickr: "1 StickR TrackR" }
  WALLET_PRIZES = { wallet: "1 Wallet TrackR"  }

  MONEY_OF_PRIZES = {
                       one_dollar_off: "$1 off",
                       free_shipping: "Free Shipping ($10 value so $10 off the order)"
                     }
  PRIZES = BRAVO_PRIZES.merge(STICKR_PRIZES).merge(WALLET_PRIZES).merge(MONEY_OF_PRIZES)

  ACTIONS = {
             facebook: "Share on Facebook",
             twitter: "Share on Twitter",
             view: "Refer a friend to view page",
             purchase: "Refer a friend to purchase"
            }
  SITES = {
           bravo: "TrackR bravo",
           stickr: "StickR TrackR",
           wallet: "Wallet TrackR"
           }

  validates :prize, :action, :site, presence: true
  validates_presence_of :number_of_friends, if: (:view_reference? || :purchase_reference?)
  validates_presence_of :link, if: :view_reference?
  validates :prize, inclusion: {in: PRIZES.values }
  validates :action, inclusion: {in: ACTIONS.values}
  validates :site, inclusion: {in: SITES.values }

  before_save do
    set_product_type
  end

  def self.filter_by_product_type(request)
    type = request.fullpath[/^\/\w+\//].gsub('/','')
    ReferralProgram.where(product_type: type)
  end

  def facebook_reference?
    get_action == :facebook
  end

  def twitter_reference?
    get_action == :twitter
  end

  def view_reference?
    get_action == :view
  end

  def purchase_reference?
    get_action == :purchase
  end

  def referral_url(assignment_id, ref_code)
    "#{link}?ref_code=#{ref_code}&program_id=#{self.id}&assignment_id=#{assignment_id}"
  end

  def process_view(assignment_id)
    assignment = Assignment.find(assignment_id)
    increment_or_complete(assignment) unless assignment.is_completed?
  end

  def process_non_view(assignment_id)
    assignment = Assignment.find(assignment_id)
    unless assignment.is_completed?
      assignment.complete
      reward(assignment.user)
    end
  end

  def tweet_url
    via = 'TheTrackR'
    tweet_text = "Lose stuff? Use your iPhone or Android to find it with TrackR."
    "https://twitter.com/intent/tweet?via=#{via}&text=#{tweet_text}"
  end

  def facebook_url
    order_type = SITES.key(self.site)
    "https://www.facebook.com/sharer/sharer.php?u=http://#{order_type}.thetrackr.com"
  end

private

  def product_reward
    if wallet_prize?
      WalletProduct.first
    elsif stickr_prize?
      StickrProduct.first
    elsif discount_prize?
      nil
    else
      BravoProduct.first
    end
  end

  def reward_order(user_id, product_id, options)
    options[:user_id] = user_id
    options[:product_id] = product_id
    options[:internal_status] = "ready_to_be_shipped"
    options[:price] = 0

    if wallet_prize?
      WalletOrder.find_or_create_bycreate(user_id: user_id, price: 0, internal_status: 'ready_to_be_shipped', product_id: product_id, quantity: 1)
    elsif stickr_prize?
      StickrOrder.find_or_create_by(user_id: user_id, price: 0, internal_status: 'ready_to_be_shipped', product_id: product_id, quantity: 1)
    elsif discount_prize?
      nil
    else
      BravoOrder.find_or_create_by(options)
    end
  end

  def add_quantity(order)
    if order.quantity
      order.quantity += 1
    else
      order.quantity = 1
    end
    order.save
  end

  def discount(user)
    if free_shipping_prize?
      Credit.find_or_initialize_by_user_id(user.id).add_amount(10)
    elsif dollar_off_prize?
      Credit.find_or_initialize_by_user_id(user.id).add_amount(1)
    elsif facebook_reference? || twitter_reference?
      Credit.find_or_initialize_by_user_id(user.id).add_amount(1)
    end
  end

  def reward(user)
    order_options = analyze_order_options
    product = product_reward
    order_for_reward  = reward_order(user.id, product.id, order_options)

    if discount_prize? || facebook_reference? || twitter_reference?
      discount(user)
    else
      add_quantity(order_for_reward)
    end
  end

  def increment_or_complete(assignment)
    assignment.increment_num_of_referrals if assignment.number_of_referrals < number_of_friends
    if assignment.number_of_referrals == number_of_friends
      assignment.complete
      reward(assignment.user)
    end
  end

  def analyze_order_options
    case get_prize
    when :bravo_steel then { color: 'steel', engraving: 'false', accessory_pack: 'false', intl_shipping: 'false' }
    when :bravo_black then { color: 'black', engraving: 'false', accessory_pack: 'false', intl_shipping: 'false' }
    when :bravo_rose_gold then { color: 'rose gold', engraving: 'false', accessory_pack: 'false', intl_shipping: 'false'}
    when :bravo_sky_blue then { color: 'sky blue', engraving: 'false', accessory_pack: 'false', intl_shipping: 'false'}
    when :bravo_steel_engrav then { color: 'steel', engraving: 'true', accessory_pack: 'false', intl_shipping: 'false' }
    when :bravo_black_engrav then { color: 'black', engraving: 'true', accessory_pack: 'false', intl_shipping: 'false' }
    when :bravo_rose_gold_engrav then { color: 'rose gold', engraving: 'true', accessory_pack: 'false', intl_shipping: 'false'}
    when :bravo_sky_blue_engrav then { color: 'sky blue', engraving: 'true', accessory_pack: 'false', intl_shipping: 'false'}
    when :bravo_steel_access then { color: 'steel', engraving: 'false', accessory_pack: 'true', intl_shipping: 'false' }
    when :bravo_black_access then { color: 'black', engraving: 'false', accessory_pack: 'true', intl_shipping: 'false' }
    when :bravo_rose_gold_access then { color: 'rose gold', engraving: 'false', accessory_pack: 'true', intl_shipping: 'false'}
    when :bravo_sky_blue_access then { color: 'sky blue', engraving: 'false', accessory_pack: 'true', intl_shipping: 'false'}
    when :bravo_steel_access_engrav then { color: 'steel', engraving: 'true', accessory_pack: 'true', intl_shipping: 'false' }
    when :bravo_black_access_engrav then { color: 'black', engraving: 'true', accessory_pack: 'true', intl_shipping: 'false' }
    when :bravo_rose_gold_access_engrav then { color: 'rose gold', engraving: 'true', accessory_pack: 'true', intl_shipping: 'false'}
    when :bravo_sky_blue_access_engrav then { color: 'sky blue', engraving: 'true', accessory_pack: 'true', intl_shipping: 'false'}
    end
  end

  def wallet_prize?
    get_prize == :wallet
  end

  def stickr_prize?
    get_prize == :stickr
  end

  def free_shipping_prize?
    get_prize == :free_shipping
  end

  def dollar_off_prize?
    get_prize == :free_shipping
  end

  def discount_prize?
    dollar_off_prize? || free_shipping_prize?
  end

  def get_action
    ACTIONS.key(self.action)
  end

  def find_assignment(user_id)
    Assignment.where(referral_program_id: self.id, user_id: user_id).last
  end

  def find_user(ref_code)
    User.find_by_ref_code(ref_code)
  end

  def get_prize
   PRIZES.key(self.prize)
  end

  def set_product_type
    self.product_type = SITES.key(self.site).to_s
  end

end
