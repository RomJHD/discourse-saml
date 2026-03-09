# frozen_string_literal: true

# name: discourse-saml
# about: SAML Auth Provider
# version: 1.0
# author: Discourse Team
# url: https://github.com/discourse/discourse-saml

gem "macaddr", "1.0.0"
gem "uuid", "2.3.7"
gem "ruby-saml", "1.18.0"

if OmniAuth.const_defined?(:AuthenticityTokenProtection) # OmniAuth 2.0
  gem "omniauth-saml", "2.2.3"
else
  gem "omniauth-saml", "1.10.5"
end

enabled_site_setting :saml_enabled if !GlobalSetting.try("saml_target_url")

on(:before_session_destroy) do |data|
  next if !DiscourseSaml.setting(:slo_target_url).present?
  data[:redirect_url] = Discourse.base_path + "/auth/saml/spslo"
end

module ::DiscourseSaml
  def self.enabled?
    # Legacy - we only check the enabled site setting
    # if the environment-variables are **not** present
    !!GlobalSetting.try("saml_target_url") || SiteSetting.saml_enabled
  end

  def self.setting(key, prefer_prefix: "saml_")
    if prefer_prefix == "saml_"
      SiteSetting.get("saml_#{key}")
    else
      GlobalSetting.try("#{prefer_prefix}#{key}") || SiteSetting.get("saml_#{key}")
    end
  end

  def self.is_saml_forced_domain?(email)
    return if !enabled?
    return if !DiscourseSaml.setting(:forced_domains).present?
    return if email.blank?

    DiscourseSaml
      .setting(:forced_domains)
      .split(/[,|]/)
      .each { |domain| return true if email.end_with?("@#{domain}") }

    false
  end
end

register_site_setting_area("saml")
register_admin_config_login_route("saml")
register_asset "stylesheets/common/discourse-saml-login.scss"

require_relative "lib/discourse_saml/saml_omniauth_strategy"
require_relative "lib/discourse_saml/saml_replay_cache"
require_relative "lib/saml_authenticator"

after_initialize do
  # Hide most SAML settings from Admin UI - they should be configured via environment variables
  # Only expose essential UI-configurable settings:
  # - Button titles (saml_button_title, saml_provider2_button_title)
  # - Role sync settings (saml_sync_admin, saml_admin_attribute, saml_sync_moderator, saml_moderator_attribute)
  # - Debug settings (saml_log_auth, saml_debug_auth)
  hidden_keys = [
    :saml_enabled,
    :saml_target_url,
    :saml_slo_target_url,
    :saml_name_identifier_format,
    :saml_cert,
    :saml_cert_fingerprint,
    :saml_cert_fingerprint_algorithm,
    :saml_provider2_target_url,
    :saml_provider2_slo_target_url,
    :saml_provider2_cert,
    :saml_cert_multi,
    :saml_request_method,
    :saml_sp_certificate,
    :saml_sp_private_key,
    :saml_authn_requests_signed,
    :saml_want_assertions_signed,
    :saml_logout_requests_signed,
    :saml_logout_responses_signed,
    :saml_request_attributes,
    :saml_attribute_statements,
    :saml_use_attributes_uid,
    :saml_skip_email_validation,
    :saml_validate_email_fields,
    :saml_default_emails_valid,
    :saml_clear_username,
    :saml_omit_username,
    :saml_auto_create_account,
    :saml_sync_groups,
    :saml_groups_fullsync,
    :saml_groups_attribute,
    :saml_groups_use_full_name,
    :saml_groups_ldap_leafcn,
    :saml_sync_groups_list,
    :saml_user_field_statements,
    :saml_sync_email,
    :saml_sync_trust_level,
    :saml_trust_level_attribute,
    :saml_sync_locale,
    :saml_locale_attribute,
    :saml_forced_domains,
    :saml_base_url,
    :saml_replay_protection_enabled,
    :saml_can_connect_existing_user,
    :saml_can_revoke,
    :saml_icon
  ]

  if SiteSetting.respond_to?(:hidden_settings_provider)
    register_modifier(:hidden_site_settings) { |hidden| hidden + hidden_keys }
  else
    SiteSetting.hidden_settings.concat(hidden_keys)
  end

  # "SAML Forced Domains" - Prevent login via email
  on(:before_email_login) do |user|
    if ::DiscourseSaml.is_saml_forced_domain?(user.email)
      raise Discourse::InvalidAccess.new(nil, nil, custom_message: "login.use_saml_auth")
    end
  end

  # "SAML Forced Domains" - Prevent login via regular username/password
  module ::DiscourseSaml::SessionControllerExtensions
    def login_error_check(user)
      if ::DiscourseSaml.is_saml_forced_domain?(user.email)
        return { error: I18n.t("login.use_saml_auth") }
      end
      super
    end
  end
  ::SessionController.prepend(::DiscourseSaml::SessionControllerExtensions)

  # "SAML Forced Domains" - Prevent login via other omniauth strategies
  class ::DiscourseSaml::ForcedSamlError < StandardError
  end
  on(:after_auth) do |authenticator, result|
    next if authenticator.name == "saml"
    if [result.user&.email, result.email].any? { |e| ::DiscourseSaml.is_saml_forced_domain?(e) }
      raise ::DiscourseSaml::ForcedSamlError
    end
  end
  Users::OmniauthCallbacksController.rescue_from(::DiscourseSaml::ForcedSamlError) do
    flash[:error] = I18n.t("login.use_saml_auth")
    render("failure")
  end
  
  # Allow GlobalSettings to override UI-configured titles.
  # If no overrides are provided, fall back to server-side translations.
  
  name = GlobalSetting.try(:saml_title)
  button_title =
    SiteSetting.saml_button_title.presence || GlobalSetting.try(:saml_button_title) ||
      I18n.t("login.saml.title")
  button_title2 =
    SiteSetting.saml_provider2_button_title.presence ||
      GlobalSetting.try(:saml_provider2_button_title) ||
      I18n.t("login.saml.provider2_title")
  
  auth_provider icon_setting: :saml_icon,
                title: button_title,
                pretty_name: name,
                authenticator: SamlAuthenticator.new
  
  # Register second SAML provider
  auth_provider icon_setting: :saml_icon,
                title: button_title2, # overridable title for second button
                pretty_name: "saml-provider2-title", # unique pretty_name for CSS targeting
                authenticator: SamlAuthenticator.new.tap { |a| a.define_singleton_method(:name) { "saml_provider2" } }
end
