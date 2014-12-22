class ReferralProgramsController < ApplicationController
  def select
    @program = ReferralProgram.find_by_id(params[:referral_program_id])
    @order = Order.find_by_id(params[:order_id])
    @assignment = Assignment.create(user_id: params[:user_id], referral_program_id: params[:referral_program_id])
    respond_to do |format|
      format.js {render :layout=>false}
    end
  end

  def tweet
   program = ReferralProgram.find(params[:program_id])
   program.process_non_view(params[:assignment_id])
   redirect_to program.tweet_url
  end

  def facebook
    program = ReferralProgram.find(params[:program_id])
    program.process_non_view(params[:assignment_id])
    redirect_to program.tweet_url
  end

  def back
    assignment = Assignment.where(user_id: params[:user_id], referral_program_id: params[:referral_program_id]).last
    assignment.destroy unless assignment.is_completed?
    respond_to do |format|
      format.js {render :layout=>false}
    end
  end

  def check_credit
    has_credit = User.find_by_email(params[:email]).try(:credit).present? ? true : false
    result = {has_credit: has_credit}
    respond_to do |format|
      format.json { render result.to_json }
    end
  end
end
