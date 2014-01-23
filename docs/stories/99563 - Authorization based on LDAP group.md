## Authorization Based on LDAP Group

AOK now supports restricting Stackato access to users that are members of certains group(s).

When configuring the LDAP strategy there are three new settings that must be set to enable this functionality.

* kato config set aok strategy/ldap/group_query 

   Specifying group_query will cause AOK to perform an additional search on the LDAP server after a user has successfully authenticated in order to fetch their group membership. %{username} will be replaced with the value of the field specified by uid. %{dn} will be replaced by the dn of the authenticated user. If using this option, you must also specify group_attribute. Set group_query to nil or false to disable this additional query.

   e.g. A group_query value of '(&(objectClass=posixGroup)(memberUid=%{username}))' will query for posixGroups that the user belongs to (remember %{username} will be replaced with the uid of the user).

* kato config set aok strategy/ldap/group_attribute 

   group_attribute is the LDAP attribute to extract from the entries returned by group_query.
   
   e.g A group_attribute value of 'cn' will extract the name of the group(s) returned by the above query, assuming the groups common name attribute does in fact contain its name.

* kato config push aok strategy/ldap/allowed_groups GROUP_NAME

   If group_query and group_attribute are configured, configure this value to specify the names of groups that are allowed to access Stackato.

   e.g. An allowed_groups value of '[admins, stackato-users]' would only let LDAP users that are a member of the 'admins' group OR the 'stackato-users' group log in to Stackato.