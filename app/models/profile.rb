require 'mandrill'
class Profile < ActiveRecord::Base
  belongs_to :order

  ACCESSORY_PACK_OPTIONS = ["Pet Collar", "Metal Loop", "Water Proof"]
  validate :engravings_length


  def email
    order.user.email
  end

  def access_link
    #TODO make it dynamic
    "http://bravo.thetrackr.com/profiles/#{id}/edit?email=#{email}"
  end

  def access_buy_link
    #TODO make it dynamic
    "http://buy.thetrackr.com/profiles/#{id}/edit?email=#{email}"
  end

  def send_bravo_profile_email
    mandrill = Mandrill::API.new
    rendered = mandrill.templates.render 'Bravo Profile Created',
      [],
      [
        { name: 'user_name', content: email },
        { name: 'bravo_profile_url', content: access_link }
      ]

    message = {
      subject: 'Order Confirmation',
      to: [{ email: email }],
      from_email: 'support@thetrackr.com',
      from_name: 'The TrackR Team',
      html: rendered['html']
    }

    mandrill.messages.send(message)
  end

  def send_buy_profile_email
    mandrill = Mandrill::API.new
    rendered = mandrill.templates.render 'Buy Profile Created',
      [],
      [
        { name: 'user_name', content: email },
        { name: 'buy_profile_url', content: access_buy_link }
      ]

    message = {
      subject: 'Order Confirmation',
      to: [{ email: email }],
      from_email: 'support@thetrackr.com',
      from_name: 'The TrackR Team',
      html: rendered['html']
    }

    mandrill.messages.send(message)
  end
private
  def engravings_length
    engravings.each_with_index do |engraving, i|
      if engraving.length > 17
        errors.add(:base, "#{(i+1).ordinalize} engraving should not contain more than 17 characters" )
      end
    end
  end
end
