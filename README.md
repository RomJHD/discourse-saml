> ⚠ Discourse has successfully integrated with SAML for many enterprises, but SAML integration is often complex, error prone, and typically requires customization / changes for that organization's _specific implementation_ of SAML. This work is best undertaken by software developers familiar with Discourse. We are highly familiar with Discourse, and available to do that work [on an enterprise hosting plan](https://discourse.org/buy).

### About

A Discourse Plugin to enable authentication via SAML

This plugin supports **dual SAML provider** configuration, allowing users to authenticate with two different SAML identity providers (e.g., separate providers for different regions or organizations).

Setting up your idp:
The entity-id should be: `http://example.com`
The consumer assertion service url should be: `https://example.com/auth/saml/callback`

You may need to set your idp to send an extra custom attribute 'screenName', that will become the users id.

For idp-initated SSO, use the following URL:
`https://example.com/auth/saml/callback`

### Configuration

For Docker based installations:

Add the following settings to your `app.yml` file in the Environment Settings section:

```
## Saml plugin setting
  DISCOURSE_SAML_TARGET_URL: https://idpvendor.com/saml/login/
  DISCOURSE_SAML_CERT_FINGERPRINT: "43:BB:DA:FF..."
  #DISCOURSE_SAML_REQUEST_METHOD: post
  #DISCOURSE_SAML_FULL_SCREEN_LOGIN: true
  DISCOURSE_SAML_CERT: "-----BEGIN CERTIFICATE-----
  ...
  -----END CERTIFICATE-----"
```
Only one of `DISCOURSE_SAML_CERT_FINGERPRINT` or `DISCOURSE_SAML_CERT` needed.

The `DISCOURSE_FULL_SCREEN_LOGIN` option allows the SSO login page to be presented within the main browser window, rather than a popup. If SAML is your only authentication method this can look neater, as when the user clicks the Log In button the login page will follow through within the main browser window rather than opening a pop-up. This setting is commented out by default - if you want full screen login uncomment that line and set the value to true (as per the example above).

For non docker:

Add the following settings to your `discourse.conf` file:

- `saml_target_url`

### Dual SAML Provider Configuration

This plugin supports configuring two separate SAML identity providers simultaneously. This is useful when you need to support authentication from different organizations or regions (e.g., Europe and Canada).

#### Using Environment Variables

Add a second provider by configuring these additional environment variables:

```
## Second SAML Provider
  DISCOURSE_SAML_PROVIDER2_TARGET_URL: https://idpvendor2.com/saml/login/
  DISCOURSE_SAML_PROVIDER2_CERT: "-----BEGIN CERTIFICATE-----
  ...
  -----END CERTIFICATE-----"
  DISCOURSE_SAML_PROVIDER2_SLO_TARGET_URL: https://idpvendor2.com/saml/logout/
```

#### Using Site Settings (Admin UI)

**By default, only the following settings are visible in Admin UI** under **Settings > SAML** for runtime configuration:

- `saml_button_title`: Customize the login button text for the first SAML provider
- `saml_provider2_button_title`: Customize the login button text for the second SAML provider  
- `saml_sync_admin`: Enable automatic admin role synchronization from SAML attributes
- `saml_admin_attribute`: SAML attribute name for admin status (default: "isAdmin")
- `saml_sync_moderator`: Enable automatic moderator role synchronization from SAML attributes
- `saml_moderator_attribute`: SAML attribute name for moderator status (default: "isModerator")
- `saml_log_auth`: Log authentication details for debugging
- `saml_debug_auth`: Enable verbose authentication debugging

**All other SAML settings are hidden from the Admin UI** and must be configured via environment variables for security and consistency. This design ensures that critical configuration like certificates, target URLs, and authentication parameters remain in your deployment configuration rather than the database.

### Complete Environment Variables Reference

All SAML plugin settings can be configured using environment variables. Prefix each setting with `DISCOURSE_` and convert to uppercase (e.g., `saml_target_url` becomes `DISCOURSE_SAML_TARGET_URL`).

#### Required Core Settings

- `DISCOURSE_SAML_TARGET_URL`: Target URL of the SAML Identity Provider (required for provider 1)
- `DISCOURSE_SAML_CERT`: X.509 public certificate of the SAML identity provider
- `DISCOURSE_SAML_CERT_FINGERPRINT`: Alternative to SAML_CERT - the X.509 certificate fingerprint

#### Provider 1 Settings

- `DISCOURSE_SAML_ENABLED`: Enable/disable SAML authentication (default: false when using site settings)
- `DISCOURSE_SAML_SLO_TARGET_URL`: Target URL for SAML Single Log Out
- `DISCOURSE_SAML_NAME_IDENTIFIER_FORMAT`: Request specific NameID format from IdP
- `DISCOURSE_SAML_CERT_FINGERPRINT_ALGORITHM`: Algorithm for certificate fingerprinting (SHA1, SHA256, SHA384, SHA512)
- `DISCOURSE_SAML_CERT_MULTI`: Secondary X.509 certificate for certificate rotation
- `DISCOURSE_SAML_REQUEST_METHOD`: GET or POST for authentication requests (default: GET)
- `DISCOURSE_SAML_ICON`: Icon identifier for the login button

#### Provider 2 Settings (Dual SAML)

- `DISCOURSE_SAML_PROVIDER2_TARGET_URL`: Target URL for second SAML Identity Provider
- `DISCOURSE_SAML_PROVIDER2_CERT`: X.509 certificate for second provider
- `DISCOURSE_SAML_PROVIDER2_SLO_TARGET_URL`: Single Logout URL for second provider

#### Button Customization

- `DISCOURSE_SAML_BUTTON_TITLE`: Login button text for first provider (overridable in Admin UI)
- `DISCOURSE_SAML_PROVIDER2_BUTTON_TITLE`: Login button text for second provider (overridable in Admin UI)
- `DISCOURSE_SAML_TITLE`: Display name for SAML provider

#### Security & Signing

- `DISCOURSE_SAML_SP_CERTIFICATE`: Service Provider X.509 certificate for signing
- `DISCOURSE_SAML_SP_PRIVATE_KEY`: Service Provider private key for signing
- `DISCOURSE_SAML_AUTHN_REQUESTS_SIGNED`: Sign authentication requests (default: false)
- `DISCOURSE_SAML_WANT_ASSERTIONS_SIGNED`: Require signed assertions (default: false)
- `DISCOURSE_SAML_LOGOUT_REQUESTS_SIGNED`: Sign logout requests (default: false)
- `DISCOURSE_SAML_LOGOUT_RESPONSES_SIGNED`: Sign logout responses (default: false)

#### Attribute Mapping

- `DISCOURSE_SAML_REQUEST_ATTRIBUTES`: Additional attributes to request (pipe-separated)
- `DISCOURSE_SAML_ATTRIBUTE_STATEMENTS`: Custom field-to-SAML-attribute mappings (format: `field:attr1,attr2|field2:attr3`)
- `DISCOURSE_SAML_USE_ATTRIBUTES_UID`: Use UID from SAML attributes instead of NameID (default: false)

#### Email & Validation

- `DISCOURSE_SAML_SKIP_EMAIL_VALIDATION`: Skip email validation (default: false)
- `DISCOURSE_SAML_VALIDATE_EMAIL_FIELDS`: Pipe-separated groups from `memberOf` to validate emails
- `DISCOURSE_SAML_DEFAULT_EMAILS_VALID`: Default email validity (default: true)
- `DISCOURSE_SAML_SYNC_EMAIL`: Sync email changes from SAML (default: false)

#### User Account Creation

- `DISCOURSE_SAML_CLEAR_USERNAME`: Clear username field on registration (default: false)
- `DISCOURSE_SAML_OMIT_USERNAME`: Omit username from registration (default: false)
- `DISCOURSE_SAML_AUTO_CREATE_ACCOUNT`: Automatically create accounts (default: false)

#### Group Synchronization

- `DISCOURSE_SAML_SYNC_GROUPS`: Enable group synchronization (default: false)
- `DISCOURSE_SAML_GROUPS_ATTRIBUTE`: SAML attribute for groups (default: "memberOf", pipe-separated)
- `DISCOURSE_SAML_GROUPS_FULLSYNC`: Fully sync groups (add AND remove) (default: false)
- `DISCOURSE_SAML_GROUPS_LDAP_LEAFCN`: Extract only group name from LDAP DN (default: false)
- `DISCOURSE_SAML_SYNC_GROUPS_LIST`: Pipe-separated list of groups to sync
- `DISCOURSE_SAML_GROUPS_USE_FULL_NAME`: Match groups by full_name instead of name (default: false)

#### Role Synchronization

- `DISCOURSE_SAML_SYNC_MODERATOR`: Sync moderator role from SAML (default: false, **configurable in Admin UI**)
- `DISCOURSE_SAML_MODERATOR_ATTRIBUTE`: SAML attribute for moderator status (default: "isModerator", **configurable in Admin UI**)
- `DISCOURSE_SAML_SYNC_ADMIN`: Sync admin role from SAML (default: false, **configurable in Admin UI**)
- `DISCOURSE_SAML_ADMIN_ATTRIBUTE`: SAML attribute for admin status (default: "isAdmin", **configurable in Admin UI**)
- `DISCOURSE_SAML_SYNC_TRUST_LEVEL`: Sync trust level from SAML (default: false)
- `DISCOURSE_SAML_TRUST_LEVEL_ATTRIBUTE`: SAML attribute for trust level (default: "trustLevel")

#### Locale & Localization

- `DISCOURSE_SAML_SYNC_LOCALE`: Sync user locale from SAML (default: false)
- `DISCOURSE_SAML_LOCALE_ATTRIBUTE`: SAML attribute for locale (default: "locale")

#### Advanced Settings

- `DISCOURSE_SAML_USER_FIELD_STATEMENTS`: Map SAML attributes to custom user fields
- `DISCOURSE_SAML_FORCED_DOMAINS`: Pipe-separated email domains that must use SAML
- `DISCOURSE_SAML_BASE_URL`: Override base URL for SAML callbacks
- `DISCOURSE_SAML_REPLAY_PROTECTION_ENABLED`: Enable replay attack protection (default: true)
- `DISCOURSE_SAML_CAN_CONNECT_EXISTING_USER`: Allow connecting SAML to existing accounts (default: true)
- `DISCOURSE_SAML_CAN_REVOKE`: Allow users to disconnect SAML (default: true)

#### Debugging (configurable in Admin UI)

- `DISCOURSE_SAML_LOG_AUTH`: Log authentication events for troubleshooting (**configurable in Admin UI**)
- `DISCOURSE_SAML_DEBUG_AUTH`: Enable verbose debug logging (**configurable in Admin UI**)

### Group Synchronization (Legacy Documentation)

For detailed group synchronization settings, see the **Complete Environment Variables Reference** section above under "Group Synchronization".

Key features:
- Sync user group memberships from SAML `memberOf` attribute
- Support for full sync (add AND remove groups) or selective sync
- LDAP DN parsing for clean group names
- Custom attribute mapping with pipe-separated sources

### Additional Notes

#### Full Screen Login

The `DISCOURSE_SAML_FULL_SCREEN_LOGIN` option allows the SSO login page to be presented within the main browser window, rather than a popup. If SAML is your only authentication method this can look neater, as when the user clicks the Log In button the login page will follow through within the main browser window rather than opening a pop-up.

### Converting an RSA Key to a PEM

If the idp has an RSA key split up as modulus and exponent, this javascript library makes it easy to convert to pem:

https://www.npmjs.com/package/rsa-pem-from-mod-exp

### Moving from environment variables to Site Settings

**Note:** By design, most SAML settings are hidden from the Admin UI and should remain in environment variables. Only button titles, role synchronization, and debugging settings are exposed in the UI.

If you need to migrate environment variables to the database for the visible settings, run this snippet in the rails console:

```ruby
SiteSetting.defaults.all.keys.each do |k|
  next if !k.to_s.start_with?("saml_")
  if val = GlobalSetting.try(k)
    puts "Setting #{k} to #{val} in the database"
    SiteSetting.add_override!(k, val)
  end
end;
SiteSetting.saml_enabled = true
```

However, it's recommended to keep critical settings (certificates, URLs, etc.) in environment variables for security and version control.

### License

MIT
