AOK Introduction
================

AOK is an Authentication Server for Stackato
--------------------------------------------

AOK was created to move the responsibility for authenticating Stackato users
outside of the Cloud Controller. This separation of responsibilities allows
AOK to support using external authentication systems in addition to a built-in
database of usernames and passwords. In particular, AOK supports authenticating
users via LDAP.

AOK is Beta Software
--------------------

This is a preview, beta-quality release of AOK for Stackato administrators who
are eager to use external mechanisms for authenticating Stackato users. Bugs 
are to be expected with early-release software. Please report bugs you find 
to us at stackato-support@activestate.com

User Experience
---------------
To be flexible enough to adapt to login UI's for a variety of authentication
systems, users are redirected away from the Stackato Web Console to a page
served by AOK when it is time for them to authenticate. Users should be
notified of this change in behavior so they are not suprised.

Users of the Stackato Client (CLI) will need to be aware of the following
changes of behavior when authenticating:

  * Although the prompt continues to say `Email:`, the user will need to enter
    their identifier as expected by the strategy in use by AOK. For example,
    many LDAP systems require the user to enter a username that is not in the
    form of an email address. In this case, the user must enter their username
    rather than their email address.
  * When using an existing authentication token to log in as a second user, the
    user must in this case use the second user's email address, *not the
    identifier used by AOK's strategy* to identify the second user.

These caveats also apply when using other Cloud-Foundry-compatible clients.

Configuration
=============

Settings
--------
AOK's configuration is stored in Doozer, and is read once when AOK starts. After
making changes to the configuration, it is necessary to restart AOK for the
changes to take effect. AOK is part of the `cloud_controller` role, so AOK may
be restarted with:

    kato restart cloud_controller

The easiest way to configure AOK is to edit the YAML
file in `config/aok.yml` and then load the saved file in to doozer using the
following command, executed from AOK's root folder `/s/aok/`:

    bundle exec rake load_config

The comments in `config/aok.yml` should help explain the purpose of the various
settings.

### Strategies ###
AOK uses the term *strategy* to refer to the method used to authenticate users.
At this time there are 2 strategies supported:

  * `builtin`
  * `ldap`

The `use` key in the configuration file controls the strategy that AOK will use.
This value must correspond exactly to one of the supported strategy names.

#### `builtin` ####
The `builtin` strategy uses a local database of email addresses and passwords to
authenticate users. *It is important to note that this strategy and database is
distinct from the Cloud Controller's internal email/password database that is
used by the Cloud Controller when AOK is disabled.* There is a script to import
users and passwords from the Cloud Controller database in to AOK for those
wishing to start using AOK while maintaining existing login credentials for
users. To import users and passwords from the Cloud Controller, execute the
following from AOK's root folder `/s/aok/`:

    # Only relevant when using the `builtin` strategy!
    bundle exec rake import_users_from_cloud_controller

#### `ldap` ####
The `ldap` strategy authenticates users using an LDAP server of the 
administrator's choosing. Any user that can successfully authenticate with the
LDAP server will be allowed to use Stackato and will have a (non-admin) user 
account created for them automatically. The LDAP server must return an email
address for the user in order for them to be able to log in to Stackato. AOK
will look for the email address under the `mail`, `email`, and 
`userPrincipalName` attributes.

LDAP groups are not currently supported as a visible construct in Stackato. 
Some support for this may be added in a future version.

Enabling
--------
AOK is disabled by default. While disabled, the Cloud Controller will continue
to use its internal email/password database to authenticate users. Execute the 
following command to enable AOK:
    
    kato config set cloud_controller aok/enabled true
    kato restart cloud_controller

If AOK is enabled before any users have been registered with the Cloud 
Controller, then the adminstrator must change the password of the unix 
`stackato` user. No automatic process will change the unix password, as would 
happen if AOK were not enabled.

User Management
---------------
When using AOK with any strategy other than `builtin`, users in Stackato will be
created automatically for any user who successfully authenticates.

User management functions in the Stackato Web Console have several caveats as a
result. Administrators can still use the functions as before, but should be
aware of the following:
  * For the time being, email addresses (used to identify users in Stackato) and
    group names are case sensitive. This will change in a future version. Please
    avoid using the same string with different casing to refer to different 
    entities.
  * Admins may manually create users if they wish. This may be useful if the 
    admin wants to pre-assign users to groups in Stackato before those users
    have logged in for the first time. The admin must create the user with the
    same email address (case-sensitive) that AOK will receive from the strategy.
  * Passwords set while creating users  or using the password-change function 
    will be disregarded - Stackato/AOK does not support changing user passwords
    in external authentication systems.
  * Admins may delete users, however the user will be recreated if they log in
    again via AOK. If an admin wishes to prevent a user from using Stackato, the
    user's login credentials should be revoked in the external authentication 
    system.

SSL Certificate
---------------
AOK by default uses the same self-signed certificate as the Cloud Controller. To
prevent log warnings about the certificate, the Cloud Controller is configured 
to use a CA file on the VM to validate AOK's certificate. This is set in Doozer 
under the `aok/ca_file` key in the Cloud Controller's configuration.