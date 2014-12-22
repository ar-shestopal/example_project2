module AdminMacros
  EMAIL = "alexde.amazon@gmail.com"
  PASSWORD = "34834amazon"

  def create_admin_user
    AdminUser.create(email: EMAIL ,password: PASSWORD, password_confirmation: PASSWORD)
  end

 def login
   visit admin_dashboard_path
   fill_in "admin_user_email", with: EMAIL
   fill_in "admin_user_password", with: PASSWORD
   click_button "Login"
 end

  def go_to_profile_edit
    find('a[href="/admin/profiles"]').click
    click_link "Edit"
  end

  def go_to_program_creation
    find('a[href="/admin/referral_programs"]').click
    within "span.action_item" do
      find('a[href="/admin/referral_programs/new?locale=en"]').click
    end
  end

  def create_program
    go_to_program_creation
    select("Refer a friend to view page", from: "Action*")
    fill_in "Number of friends", with: 2
    fill_in "Link", with: "http://localhost:#{Capybara.server_port}"
    select("TrackR bravo", from: "referral_program_site")
    select("1 TrackR bravo steel", from: "referral_program_prize")
    click_button "Create Referral program"
  end
end
