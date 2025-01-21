module CrownMarketplace::ManageUsersHelper
  def add_users_back_link(user, section_name)
    link_params = {
      roles: user.roles,
      service_access: user.service_access,
      email: user.email,
      telephone_number: user.telephone_number
    }

    add_user_crown_marketplace_manage_users_path(section: section_name, **link_params.compact_blank)
  end

  def enabled_disabled_status_tag(enabled)
    if enabled
      [t('crown_marketplace.manage_users.edit_partials.account_status.options.enabled')]
    else
      [t('crown_marketplace.manage_users.edit_partials.account_status.options.disabled'), :red]
    end
  end

  def verified_unverified_status_tag(verified)
    if verified
      [t('crown_marketplace.manage_users.edit_partials.email_verified.options.verified.')]
    else
      [t('crown_marketplace.manage_users.edit_partials.email_verified.options.unverified.'), :grey]
    end
  end

  def user_confirmation_status_tag(confirmation_status)
    colour = case confirmation_status
             when 'CONFIRMED'
               nil
             when 'COMPROMISED'
               :red
             else
               :grey
             end

    [confirmation_status, colour]
  end
end
