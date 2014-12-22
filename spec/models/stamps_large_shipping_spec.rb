require 'rails_helper'

RSpec.describe StampsLargeShipping, :type => :model do
  subject  {StampsLargeShipping.new(Order.new)}
  it { should respond_to :create_stamp! }
  it { should respond_to :failed? }

  it "should have specific package type" do
    expect(StampsLargeShipping::PACKAGE_TYPE).to eq "Large Envelope"
  end
end
