require 'rails_helper'

describe ReferralProgram do
  after(:all) do
    ReferralProgram.destroy_all
    User.destroy_all
    Assignment.destroy_all
    Product.destroy_all
    Order.destroy_all
  end

  describe "validations" do
    let(:program) { FactoryGirl.build(:referral_program, prize: nil)}

    it "should have prize" do
      expect(program).not_to be_valid
    end
  end

  describe "product_type" do
    it "should set program type according to site" do
      program = FactoryGirl.create(:referral_program, site: ReferralProgram::SITES[:bravo])
      expect(program.product_type).to eq("bravo")
    end

    it "should find only bravo programs" do
      FactoryGirl.create(:referral_program, site: ReferralProgram::SITES[:bravo])
      FactoryGirl.create(:referral_program, site: ReferralProgram::SITES[:stickr])
      FactoryGirl.create(:referral_program, site: ReferralProgram::SITES[:wallet])

      programs = ReferralProgram.filter_by_product_type(:bravo)
      expect(programs.size).to eq(1)
      expect(programs.first.site).to eq(ReferralProgram::SITES[:bravo])
      expect(programs.first.product_type).to eq("bravo")
    end
  end

  describe "reference" do
    it "should reference to view" do
      program = FactoryGirl.create(:referral_program, action: "Refer a friend to view page")
      expect(program.view_reference?).to be_truthy
    end

    it "should reference to purchase" do
      program = FactoryGirl.create(:referral_program, action: "Refer a friend to purchase")
      expect(program.purchase_reference?).to be_truthy
    end

    it "should reference to twitter" do
      program = FactoryGirl.create(:referral_program, action: "Share on Twitter")
      expect(program.twitter_reference?).to be_truthy
    end

    it "should reference to twitter" do
      program = FactoryGirl.create(:referral_program, action: "Share on Facebook")
      expect(program.facebook_reference?).to be_truthy
    end
  end

  describe "check if finished" do
    context "find" do
      before :each do
        @program = FactoryGirl.create(:referral_program)
        @user = FactoryGirl.create(:user)
        @assignment = FactoryGirl.create(:assignment, user: @user, referral_program: @program)
      end

      it "should find user" do
        expect(@user.ref_code).not_to be_nil
        expect(@program.send(:find_user, @user.ref_code)).to eq @user
      end

      it "should find assignment" do
        expect(@program.send(:find_assignment, @user.id)).to eq @assignment
      end
    end

    context "process view related program" do
      it "should increment number_of_referrals and complete assignment" do
        assignment = FactoryGirl.create(:assignment, number_of_referrals: 1)
        program = FactoryGirl.create(:referral_program, number_of_friends: 2)

        program.send(:process_view_related, assignment)
        expect(assignment.number_of_referrals).to eq 2
        expect(assignment.is_completed).to be_truthy
      end

      it "should increment number_of_referrals but not complete assignment" do
        assignment = FactoryGirl.create(:assignment, number_of_referrals: 1)
        program = FactoryGirl.create(:referral_program, number_of_friends: 3)
        program.send(:process_view_related, assignment)
        expect(assignment.is_completed).not_to be_truthy
      end
    end
  end

  describe "prize" do
    it "should define prize" do
      program = FactoryGirl.build(:referral_program)
      program.prize = "1 StickR TrackR"
      expect(program.stickr_prize?).to be_truthy
      program.prize = "1 Wallet TrackR"
      expect(program.wallet_prize?).to be_truthy
      program.prize = "Free Shipping ($10 value so $10 off the order)"
      expect(program.free_shipping_prize?).to be_truthy
      expect(program.discount_prize?).to be_truthy
    end
  end

  describe "reward" do
    let(:bravo_program) { FactoryGirl.build(:referral_program, prize: ReferralProgram::BRAVO_PRIZES[:bravo_steel])}
    let(:wallet_program) { FactoryGirl.build(:referral_program, prize: ReferralProgram::WALLET_PRIZES[:wallet])}
    let(:stickr_program) { FactoryGirl.build(:referral_program, prize: ReferralProgram::STICKR_PRIZES[:stickr])}

    it "should return correct product options hash" do
      correct_bravo_options =  { color: 'steel', engraving: 'false', accessory_pack: 'false', intl_shipping: 'false', quantity: 1 }
      expect(bravo_program.send(:analyze_product_options)).to eq correct_bravo_options
    end

     it "should find bravo product"  do
       bravo_product = BravoProduct.create(title: "title", price: 0, shipping_price: 0, quantity: 1, description: bravo_program.prize)
       option = bravo_program.prize
       expect(bravo_program.send(:product_reward, option)).to eq bravo_product
     end

     it "should create new bravo order" do
       user = FactoryGirl.create(:user)
       bravo_program.send(:new_order,user.id, 1)
       expect(BravoOrder.count).to eq (1)
     end

     it "should find wallet product"  do
       wallet_product = WalletProduct.create(title: "title", price: 0, shipping_price: 0, quantity: 1, description: bravo_program.prize)
       option = wallet_program.prize
       expect(wallet_program.send(:product_reward, option)).to eq wallet_product
     end

     it "should create new wallet order" do
       user = FactoryGirl.create(:user)
       wallet_program.send(:new_order,user.id, 1)
       expect(WalletOrder.count).to eq (1)
     end

     it "should find stickr product"  do
       stickr_product = StickrProduct.create(title: "title", price: 0, shipping_price: 0, quantity: 1, description: bravo_program.prize)
       option = stickr_program.prize
       expect(stickr_program.send(:product_reward, option)).to eq stickr_product
     end

     it "should create new stickr order" do
       user = FactoryGirl.create(:user)
       stickr_program.send(:new_order,user.id, 1)
       expect(StickrOrder.count).to eq (1)
     end

     context "give reward" do
       let(:user) {FactoryGirl.create(:user)}
       let!(:bravo_product) { BravoProduct.create(title: "title", price: 0, shipping_price: 0, quantity: 1, description: bravo_program.prize)}

       it "should set new order if user has no order" do
         bravo_program.send(:reward, user)

         expect(BravoOrder.count).to eq 1
       end

       it "should add quantity if user has unsheeped order" do
         order = BravoOrder.create(user_id: user.id, price: 0, internal_status: 'ready_to_be_shipped', product_id: bravo_product.id, quantity: 1)
         bravo_program.send(:reward, user)

         expect(BravoOrder.first.quantity).to eq 2
       end
     end
   end

   describe "referral program link processing" do
     before :each do
       @user = FactoryGirl.create(:user)
       @bravo_program = FactoryGirl.create(:referral_program, number_of_friends: 1, action: ReferralProgram::ACTIONS[:view],  prize: ReferralProgram::BRAVO_PRIZES[:bravo_steel])
       @bravo_product = BravoProduct.create(title: "title", price: 0, shipping_price: 0, quantity: 1, description: @bravo_program.prize)
       @assignment = FactoryGirl.create(:assignment, number_of_referrals: 0, user: @user, referral_program: @bravo_program )
       @order = BravoOrder.create(user_id: @user.id, price: 0, internal_status: 'ready_to_be_shipped',  product_id: @bravo_product.id, quantity: 1)
       @cookies = {}
       @params = {ref_code: @user.ref_code, program_id: @bravo_program.id }

       ReferralProgram.view_reference(@params, @cookies)
     end

     after :each do
       User.destroy_all
       ReferralProgram.destroy_all
       BravoProduct.destroy_all
       Assignment.destroy_all
       Order.destroy_all
     end

     context "view related referral program" do
       before :each do
         User.destroy_all
         ReferralProgram.destroy_all
         BravoProduct.destroy_all
         Assignment.destroy_all
         Order.destroy_all


         @user = FactoryGirl.create(:user)
         @bravo_program = FactoryGirl.create(:referral_program, number_of_friends: 1, action: ReferralProgram::ACTIONS[:view],  prize: ReferralProgram::BRAVO_PRIZES[:bravo_steel])
         @bravo_product = BravoProduct.create(title: "title", price: 0, shipping_price: 0, quantity: 1, description: @bravo_program.prize)
         @assignment = FactoryGirl.create(:assignment, number_of_referrals: 0, user: @user, referral_program: @bravo_program )
         @order = BravoOrder.create(user_id: @user.id, price: 0, internal_status: 'ready_to_be_shipped',  product_id: @bravo_product.id, quantity: 1)
         @cookies = {}
         @params = {ref_code: @user.ref_code, program_id: @bravo_program.id }

         ReferralProgram.view_reference(@params, @cookies)
       end

       after :each do
         User.destroy_all
         ReferralProgram.destroy_all
         BravoProduct.destroy_all
         Assignment.destroy_all
         Order.destroy_all
       end

       # def self.view_reference(params, cookies)
       #   if params[:ref_code].present? && params[:program_id].present? && ReferralProgram.not_visited?(params, cookies)
       #     program = ReferralProgram.find_by_id(params[:program_id])
       #     program.process_view(params[:ref_code], params[:program_id]) if program.view_reference?
       #     ReferralProgram.set_cookies(params, cookies)
       #   end
       # end

       it "should set cookies" do
         expect(@cookies[:ref_code]).not_to be_nil
         expect(@cookies[:ref_code]).to eq @user.ref_code
       end

       it "should complete assignment" do
         expect(Assignment.find(@assignment.id).is_completed).to be_truthy
       end

       it "should increase orders quantity" do
         expect(Order.find(@order.id).quantity).to eq 2
       end
     end

     context "non view related" do
       before :each do
         User.destroy_all
         ReferralProgram.destroy_all
         BravoProduct.destroy_all
         Assignment.destroy_all
         Order.destroy_all

         @user = FactoryGirl.create(:user)
         @bravo_product = BravoProduct.create(title: "title", price: 0, shipping_price: 0, quantity: 1, description: @bravo_program.prize)

         @new_order = BravoOrder.create(user_id: @user.id, price: 0, internal_status: 'ready_to_be_shipped',  product_id: @bravo_product.id, quantity: 1)
         @bravo_program = FactoryGirl.create(:referral_program, number_of_friends: 1, action: ReferralProgram::ACTIONS[:purchase],  prize: ReferralProgram::BRAVO_PRIZES[:bravo_steel])
         @cookies = {ref_code: @user.ref_code, program_id: @bravo_program.id }
         @assignment = FactoryGirl.create(:assignment, number_of_referrals: 0, user: @user, referral_program: @bravo_program )

         ReferralProgram.purchase_reference(@cookies)
       end

       it "should complete assignment" do
         expect(Assignment.find(@assignment.id).is_completed).to be_truthy
       end

       it "should increase orders quantity" do
         expect(BravoOrder.find(@new_order.id).quantity).to be 2
       end


     end
   end
end
