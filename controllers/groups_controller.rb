class GroupsController < ApplicationController

        # XXX Test only methods:
        # Reset -- delete all groups
        get '/RESET/' do
          Group.delete_all
          return
        end
        # TODO Move these to test-only class.

  # Create a Group
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#create-a-group-post-group
  post '/?' do
    # authenticate!
    group = Group.new
    set_group_details group, read_json_body
    if group.save
      return 201, group_hash(group).to_json
    else
      handle_save_error group
    end
  end

  # Get a specific Group by guid
  get '/:id' do
    # authenticate!
    id = params[:id]
    group = Group.find_by_guid(id)
    raise Aok::Errors::ScimNotFound.new("Group #{id} does not exist") \
      unless group
    group_hash(group).to_json
  end

  # Update a Group
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#update-a-group-patch-groupid
  patch '/:id' do
    # authenticate!
    # XXX check that user is not already in group
    group = Group.find_by_guid(params[:id])
    read_json_body['members'].each do |user|
      user_guid = user['value']
      identity = Identity.find_by_guid(user_guid)
      if user['operation'].downcase == 'delete'
        group.identities.delete(identity)
      else
        group.identities << identity
      end
    end

    if group.save
      return 200, group_hash(group).to_json
    else
      handle_save_error group
    end
  end

  # Update a Group
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#update-a-group-put-groupid
  put '/:id' do
    # authenticate!
    id = params[:id]
    group = Group.find_by_guid(id)
    raise Aok::Errors::ScimNotFound.new("Group #{id} does not exist") \
      unless group
    set_group_details group, read_json_body
    if group.save
      return 200, group_hash(group).to_json
    else
      handle_save_error group
    end
  end

  # Query for Information
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#query-for-information-get-groups
  get '/?' do
    filter = true
    begin
      if params[:filter]
        filter = Aok::Scim::ActiveRecordQueryBuilder \
          .new.build_query(params[:filter])
      end
    rescue
      raise Aok::Errors::ScimFilterError.new($!.message)
    end
    resources = Group.where(filter).collect do |group|
      group_hash group
    end

    return {
      'schemas' => ["urn:scim:schemas:core:1.0"],
      'resources' => resources,
      'totalResults' => resources.size
    }.to_json
  end

  # Delete a Group
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#delete-a-group-delete-groupid
  delete '/:id' do
    # authenticate!
    id = params[:id]
    group = Group.find_by_guid(id)
    raise Aok::Errors::ScimNotFound.new("Group #{id} does not exist") \
      unless group
    group.destroy
    return 200
  end

  def set_group_details group, group_details
    group.name = group_details['displayName']
    if group_details['members']
      group.identities = []
      group.groups = []
      group_details['members'].each do |member_hash|
        case member_hash['type']
        when 'GROUP'
          g = Group.find_by_guid member_hash['value']
          if g.nil?
            raise Aok::Errors::ScimGroupInvalid.new("Invalid group member: #{member_hash['value']}.")
          end
          group.groups << g
        when 'USER', nil
          i = Identity.find_by_guid member_hash['value']
          if i.nil?
            raise Aok::Errors::ScimGroupInvalid.new("Invalid group member: #{member_hash['value']}.")
          end
          group.identities << i
        else
          raise Aok::Errors::ScimGroupInvalid.new("Invalid group: Group member type #{member_hash['type'].inspect} not supported.")
        end
      end
    end
    return group
  end

  def patch_group array
    {
      "schemas" => ["urn:scim:schemas:core:1.0"],
      "members" => array,
    }
  end

  def group_hash group
    {
      :schemas => ["urn:scim:schemas:core:1.0"],
      :meta => {
        :version => group.version
      },
      :id => group.guid,
      :displayName => group.name,
      :members => group.identities.collect do |user|
        {
          :type => 'USER',
          :value => user.guid,
        }
      end + group.groups.collect do |g|
        {
          :type => 'GROUP',
          :value => g.guid
        }
      end,
    }
  end

  def handle_save_error group
    error = 'invalid_scim_resource'
    status 400
    if (group.errors[:name] && group.errors[:name].any?{|e|e =~ /taken/})
      status 409
      error = 'scim_resource_already_exists'
    end
    return  {
      :error => error,
      :error_description => group.errors.full_messages.join('. ')
    }.to_json
  end

end
