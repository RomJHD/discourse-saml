> ⚠ Discourse has successfully integrated with SAML for many enterprises, but SAML integration is often complex, error prone, and typically requires customization / changes for that organization's _specific implementation_ of SAML. This work is best undertaken by software developers familiar with Discourse. We are highly familiar with Discourse, and available to do that work [on an enterprise hosting plan](https://discourse.org/buy).

### About

A Discourse Plugin to enable authentication via SAML

This plugin supports **dual SAML provider** configuration, allowing users to authenticate with two different SAML identity providers (e.g., separate providers for different regions or organizations).

**Setting up your Identity Provider (IdP):**

Configure your SAML IdP with these Service Provider (SP) details:

- **Entity ID (Issuer)**: Your Discourse forum URL (e.g., `https://forum.example.com`)
- **Assertion Consumer Service (ACS) URL**: `https://forum.example.com/auth/saml/callback`
- **Single Logout (SLO) URL** (optional): `https://forum.example.com/auth/saml/slo`

For the second provider (if using dual SAML):
- **ACS URL**: `https://forum.example.com/auth/saml_provider2/callback`
- **SLO URL**: `https://forum.example.com/auth/saml_provider2/slo`

**Recommended IdP Attributes:**

Your IdP should send these attributes in the SAML response:
- `email` or `mail` - User's email address (required)
- `screenName` - Username (recommended if not using email as username)
- `name` or `fullName` - User's display name
- `first_name`/`firstName` and `last_name`/`lastName` - Can be combined to create display name

**IdP-Initiated SSO:**

For IdP-initiated SSO (logging in from your IdP portal), configure the ACS URL as shown above in your IdP settings.

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

**Note:** You do NOT need to set `DISCOURSE_SAML_ENABLED` when using environment variables. The plugin automatically enables itself when `DISCOURSE_SAML_TARGET_URL` is configured. The `DISCOURSE_SAML_ENABLED` setting is only used when configuring SAML entirely through the Admin UI without environment variables.

**Optional - Full Screen Login:**

The `DISCOURSE_SAML_FULL_SCREEN_LOGIN` option (a Discourse core feature) allows the SSO login page to be presented within the main browser window, rather than a popup. If SAML is your only authentication method, this can look neater.

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

**Note:** The second provider shares most configuration settings with the first provider (such as certificate fingerprint algorithm, request method, signing options, attribute mappings, group sync, and role sync). Only the target URL, certificate, SLO URL, and button title are provider-specific. See the "Provider 2 Settings" section below for details.

#### Using Site Settings (Admin UI)

**By default, only the following settings are visible in Admin UI** under **Settings > SAML** for runtime configuration:

- `saml_button_title`: Customize the login button text for the first SAML provider
- `saml_provider2_button_title`: Customize the login button text for the second SAML provider  
- `saml_sync_admin`: Enable automatic admin role synchronization from SAML attributes
- `saml_admin_attribute`: SAML attribute name for admin status (default: "isAdmin")
- `saml_sync_moderator`: Enable automatic moderator role synchronization from SAML attributes
- `saml_moderator_attribute`: SAML attribute name for moderator status (default: "isModerator")
- `saml_forced_domains`: List of email domains that must use SAML authentication (pipe-separated, e.g., company.com|subsidiary.com)
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

- `DISCOURSE_SAML_ENABLED`: Enable/disable SAML authentication. **Only needed when configuring via Site Settings (Admin UI) instead of environment variables.** If you set `DISCOURSE_SAML_TARGET_URL` as an environment variable, the plugin auto-enables and this setting is not required.
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

**Important:** Provider 2 only has dedicated settings for the above three parameters plus its button title. **All other settings are shared with Provider 1**, including:
- Certificate fingerprint algorithm (`DISCOURSE_SAML_CERT_FINGERPRINT_ALGORITHM`)
- Request method (`DISCOURSE_SAML_REQUEST_METHOD`)
- Name identifier format (`DISCOURSE_SAML_NAME_IDENTIFIER_FORMAT`)
- All signing options (`*_SIGNED` settings)
- Attribute mappings and statements
- Group synchronization settings
- Role synchronization settings
- Email validation settings
- Debug and logging settings

This means both providers will use the same authentication flow configuration, attribute parsing, and synchronization behavior, but connect to different identity providers.

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

- `DISCOURSE_SAML_SKIP_EMAIL_VALIDATION`: Skip email validation entirely (default: false)
- `DISCOURSE_SAML_VALIDATE_EMAIL_FIELDS`: Pipe-separated group names from `memberOf` attribute. If the user is in any of these groups, email is validated. Otherwise, email validation is skipped. This overrides `DISCOURSE_SAML_DEFAULT_EMAILS_VALID`.
- `DISCOURSE_SAML_DEFAULT_EMAILS_VALID`: Whether to trust emails from SAML by default (default: true)
- `DISCOURSE_SAML_SYNC_EMAIL`: Allow SAML to update user's email address on subsequent logins (default: false)

#### User Account Creation

- `DISCOURSE_SAML_CLEAR_USERNAME`: Clear the username field on registration form (default: false)
- `DISCOURSE_SAML_OMIT_USERNAME`: Skip username selection entirely, auto-generate from email/attributes (default: false)
- `DISCOURSE_SAML_AUTO_CREATE_ACCOUNT`: Automatically create accounts without showing registration popup. Only works if email is validated (default: false)

#### Group Synchronization

- `DISCOURSE_SAML_SYNC_GROUPS`: Enable group synchronization from SAML attributes (default: false)
- `DISCOURSE_SAML_GROUPS_ATTRIBUTE`: SAML attribute containing group memberships (default: "memberOf"). Accepts pipe-separated attribute names to check multiple sources (e.g., "memberOf|groups")
- `DISCOURSE_SAML_GROUPS_FULLSYNC`: Completely sync groups - add AND remove based on IdP data. When true, ignores `groups_to_add`/`groups_to_remove` attributes (default: false)
- `DISCOURSE_SAML_GROUPS_LDAP_LEAFCN`: Extract only the group name from LDAP Distinguished Names. Converts `cn=groupname,cn=groups,dc=example,dc=com` to just `groupname`. Useful for Discourse's 20-character group name limit (default: false)
- `DISCOURSE_SAML_SYNC_GROUPS_LIST`: Pipe-separated list of Discourse groups to sync. If provided, only these groups will be synced. Other groups are ignored.
- `DISCOURSE_SAML_GROUPS_USE_FULL_NAME`: Match groups using Discourse's `full_name` field instead of the `name` field. Allows spaces in group names like "North Africa" instead of "north_africa" (default: false)

**Note:** Your IdP can also send `groups_to_add` and `groups_to_remove` attributes to dynamically control group membership per login when fullsync is disabled.

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

- `DISCOURSE_SAML_USER_FIELD_STATEMENTS`: Map SAML attributes to Discourse custom user fields. Format: `saml_attribute:field_id|another_attr:field_id` (e.g., `department:2|title:3` maps the SAML `department` attribute to user field ID 2)
- `DISCOURSE_SAML_FORCED_DOMAINS`: Pipe-separated email domains that must authenticate via SAML. Users with these domains are blocked from password, email, and other OAuth logins (e.g., `company.com|subsidiary.com`). **Can be configured in Admin UI.**
- `DISCOURSE_SAML_BASE_URL`: Override base URL for the Service Provider. Defaults to the forum base URL. Useful when behind a proxy.
- `DISCOURSE_SAML_REPLAY_PROTECTION_ENABLED`: Enable replay attack protection by tracking assertion IDs (default: true)
- `DISCOURSE_SAML_CAN_CONNECT_EXISTING_USER`: Allow users to connect SAML to their existing Discourse accounts (default: true)
- `DISCOURSE_SAML_CAN_REVOKE`: Allow users to disconnect SAML from their account settings (default: true)

#### Debugging (configurable in Admin UI)

- `DISCOURSE_SAML_LOG_AUTH`: Log authentication events for troubleshooting (**configurable in Admin UI**)
- `DISCOURSE_SAML_DEBUG_AUTH`: Enable verbose debug logging (**configurable in Admin UI**)

### Important Features & Automatic Behaviors

#### Automatic Plugin Enablement

When `DISCOURSE_SAML_TARGET_URL` is set as an environment variable, the plugin **automatically enables itself**. You do not need to set `DISCOURSE_SAML_ENABLED=true`. The enabled setting is only required when configuring SAML entirely through the Admin UI without environment variables.

#### Single Logout (SLO) Behavior

When `DISCOURSE_SAML_SLO_TARGET_URL` (or `DISCOURSE_SAML_PROVIDER2_SLO_TARGET_URL`) is configured, logging out of Discourse will automatically redirect users to the Identity Provider's logout endpoint. This ensures users are logged out of both Discourse and the IdP.

#### SAML Forced Domains

The `DISCOURSE_SAML_FORCED_DOMAINS` setting (also configurable in Admin UI as `saml_forced_domains`) allows you to specify email domains (pipe-separated, e.g., `company.com|subsidiary.com`) where users **must** authenticate via SAML. Users with these email domains will be:
- Blocked from logging in with username/password
- Blocked from logging in with email/magic link
- Blocked from using other OAuth providers (Google, GitHub, etc.)
- Forced to use only the SAML authentication flow (both Provider 1 and Provider 2 are allowed)

This is useful for enforcing SSO for corporate domains while allowing other users to use regular authentication.

#### Replay Attack Protection

Replay protection is **enabled by default** (`DISCOURSE_SAML_REPLAY_PROTECTION_ENABLED=true`). This prevents SAML assertions from being reused in replay attacks. The plugin tracks assertion IDs and rejects duplicate submissions.

#### Auto-Create Accounts

When `DISCOURSE_SAML_AUTO_CREATE_ACCOUNT=true` is set, users authenticating via SAML will have their accounts created automatically without showing the registration popup. The account is created with:
- Email from SAML assertion
- Username suggested from SAML attributes (screenName, name, or email)
- Name from SAML attributes (first_name + last_name, or name field)

**Important:** Auto-creation only happens if the email is validated (see email validation below).

#### Email Validation Behavior

By default, emails from SAML are trusted (`DISCOURSE_SAML_DEFAULT_EMAILS_VALID=true`). However, you can use `DISCOURSE_SAML_VALIDATE_EMAIL_FIELDS` to conditionally validate emails based on group membership:

- Provide pipe-separated group names (e.g., `verified_users|employees`)
- The plugin checks if any of these groups appear in the user's `memberOf` SAML attribute
- If a match is found, email is marked as validated
- If no match, email is marked as unvalidated (overriding the default)

This is useful when your IdP provides different levels of email verification.

#### Entity ID and Service URLs

The plugin automatically configures SAML Service Provider metadata:
- **Entity ID (Issuer)**: Uses your Discourse base URL (e.g., `https://forum.example.com`) by default
- **Assertion Consumer Service URL**: `https://forum.example.com/auth/saml/callback`
- **Single Logout Service URL**: `https://forum.example.com/auth/saml/slo`

For Provider 2:
- **Assertion Consumer Service URL**: `https://forum.example.com/auth/saml_provider2/callback`
- **Single Logout Service URL**: `https://forum.example.com/auth/saml_provider2/slo`

You can override the base URL using `DISCOURSE_SAML_BASE_URL` if your Discourse instance is behind a proxy or uses a different public URL.

#### IdP-Initiated SSO

The plugin supports Identity Provider-initiated SSO. Users can log in by accessing the IdP portal first, then being redirected to Discourse. The callback URL for IdP-initiated SSO is:
- Provider 1: `https://forum.example.com/auth/saml/callback`
- Provider 2: `https://forum.example.com/auth/saml_provider2/callback`

Configure this as the "Assertion Consumer Service URL" in your IdP settings.

#### Default Attribute Mapping

The plugin automatically maps these SAML attributes (if provided by your IdP):
- **Email**: `email` or `mail`
- **Name**: `fullName` or `name`
- **First Name**: `first_name`, `firstname`, or `firstName`
- **Last Name**: `last_name`, `lastname`, or `lastName`
- **Username**: `screenName`

You can customize these mappings using `DISCOURSE_SAML_ATTRIBUTE_STATEMENTS`.

#### Group Synchronization with groups_to_add/groups_to_remove

In addition to the `memberOf` attribute, your SAML IdP can send special attributes:
- `groups_to_add`: Comma-separated list of Discourse groups to add the user to
- `groups_to_remove`: Comma-separated list of Discourse groups to remove the user from

These work alongside `memberOf` when `DISCOURSE_SAML_GROUPS_FULLSYNC=false` (the default).

#### Role Synchronization Timing

When role sync settings are enabled (`DISCOURSE_SAML_SYNC_ADMIN`, `DISCOURSE_SAML_SYNC_MODERATOR`, `DISCOURSE_SAML_SYNC_TRUST_LEVEL`), the synchronization happens:
- **On every login** for existing users
- **On account creation** for new users

This means roles are constantly updated based on the latest SAML data from your IdP.

### Group Synchronization (Legacy Documentation)

For detailed group synchronization settings, see the **Complete Environment Variables Reference** section above under "Group Synchronization".

Key features:
- Sync user group memberships from SAML `memberOf` attribute
- Support for full sync (add AND remove groups) or selective sync
- LDAP DN parsing for clean group names
- Custom attribute mapping with pipe-separated sources

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
SiteSetting.saml_enabled = true  # Required when removing DISCOURSE_SAML_TARGET_URL env var
```

However, it's recommended to keep critical settings (certificates, URLs, etc.) in environment variables for security and version control.

### License

MIT
