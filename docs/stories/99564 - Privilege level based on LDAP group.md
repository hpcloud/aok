## Privilege Level Based on LDAP Group

AOK now supports granting admin privilege level to Stackato users who are members of certain LDAP groups.

When configuring the LDAP strategy there are three new settings that must be set to enable this functionality.

* kato config set aok strategy/ldap/group_query
* kato config set aok strategy/ldap/group_attribute 
	[both explained in story for 99563]

* kato config push aok strategy/ldap/admin_groups GROUP_NAME

   If group_query and group_attribute are configured, specify the names of groups whose members should be granted admin privilege. The user will be granted admin the first time they log in while a member of a listed LDAP group, and will remain an admin even if they are later removed from the LDAP group. This should be an array of Strings.

   e.g. An admin_groups value of '[admins, bosses]' would grant Stackato admin status to any LDAP user who is a member of the 'admins' LDAP group OR the 'bosses' LDAP group.
