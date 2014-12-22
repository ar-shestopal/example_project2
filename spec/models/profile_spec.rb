require 'rails_helper'

RSpec.describe Profile, :type => :model do
  let(:profile) {Profile.new}
  it "should belong to user" do
    expect(profile).to respond_to(:bravo_order)
  end

  it "should validate engravings" do
    profile.engravings << "This engraving is too long"
    profile.valid?
    expect(profile.errors[:base]).to include("1st engraving should not contain more than 17 characters")
  end
end
