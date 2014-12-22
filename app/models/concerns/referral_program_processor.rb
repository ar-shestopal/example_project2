module  ReferralProgramProcessor

  def self.set_cookies(params, cookies)
    if params[:ref_code].present? && params[:program_id].present? && params[:assignment_id].present?
      cookies[:ref_code] = params[:ref_code]
      cookies[:program_id] = params[:program_id]
      cookies[:assignment_id] = params[:assignment_id]
    end
  end

  def self.unset_cookies(params, cookies)
    cookies.delete :ref_code if cookies[:ref_code].present?
    cookies.delete :program_id if cookies[:program_id].present?
    cookies.delete :assignment_id if cookies[:assignment_id].present?
  end

  def self.cookies_set?(cookies)
    cookies[:ref_code].present? && cookies[:program_id].present? && cookies[:assignment_id].present?
  end

  def self.not_visited?(params, cookies)
    if params[:ref_code].present? && params[:program_id].present? && params[:assignment_id].present?
      !(params[:ref_code] == cookies[:ref_code] && params[:program_id] == cookies[:program_id] && params[:assignment_id] == cookies[:assignment_id])
    else
      false
    end
  end

  ##Check if referral program is completed by User
  def self.view_reference(params, cookies, request)
    program = ReferralProgram.find_by_id(params[:program_id])
    if (program.view_reference? && request_url(request) == program.link)
      program.process_view(params[:assignment_id])
      set_cookies(params, cookies)
    end
  end

  def self.purchase_reference
    if cookies_set?
      program = ReferralProgram.find(cookies[:program_id])
      program.process_non_view(cookies[:assignment_id]) if program.purchase_reference?
    end
  end

  def self.request_url(request)
    request.original_url.split('?').first[0..-2]
  end

end
