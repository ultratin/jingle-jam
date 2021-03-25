module LoginHelpers
  def log_in_with(email_address, otp_secret:, visit_page: true, expect_failure: false)
    visit "/admin/login" if visit_page
    fill_in "Email", with: email_address
    fill_in "Password", with: "password"
    click_on "Login"

    complete_2sv(otp_secret) if otp_secret.present?

    unless expect_failure
      expect(page).to have_css("#current_user a", text: email_address)
      @current_admin_user = AdminUser.find_by(email: email_address)
    end
  end

  def complete_2sv(otp_secret)
    fill_in "112233", with: ROTP::TOTP.new(otp_secret).at(Time.zone.now)
    click_on "Verify"
  end

  def log_in_as(user_or_factory, traits: nil, **kwargs)
    user = case user_or_factory
    when Symbol
      FactoryBot.create(user_or_factory, *traits)
    when AdminUser, Donator
      user_or_factory
    else
      raise ArgumentError, "Please provide an `AdminUser`/`Donator` instance, or a factory name."
    end

    case user
    when Donator
      use_magic_link(user)
    when AdminUser
      log_in_with(user.email, otp_secret: user.otp_secret, **kwargs)
    end
  end

  def use_magic_link(donator)
    visit magic_redirect_path(donator_id: donator.id, hmac: donator.hmac)
  end

  def ensure_logged_in(as: :donator, **kwargs)
    return if @current_user

    log_in_as(as, **kwargs)
  end
end

World(LoginHelpers)
