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
    # authenticate! #TODO enforce permissions on this call
    group_details = read_json_body
    group = Group.new
    set_group_details group, group_details
    logger.debug group_details.inspect
    logger.debug group.inspect
    if group.save
      return 201, scim_group_response(group)
    else
      handle_save_error group
    end
  end

  # Update a Group
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#update-a-group-put-groupid
  put '/:id' do
    raise Aok::Errors::NotImplemented
  end

  # Query for Information
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#query-for-information-get-groups
  get '/?' do
    begin
      filter = if params[:filter]
        Aok::Scim::ActiveRecordQueryBuilder.new.build_query(params[:filter])
      else
        true
      end
    rescue
      raise Aok::Errors::ScimFilterError.new($!.message)
    end
    groups = Group.where(filter)
    resources = []
    groups.each do |group|
      resources.push({
        "id" => group.id,
      })
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
    raise Aok::Errors::NotImplemented
  end

  def set_group_details group, group_details
    group.name = group_details['displayName']
  end

  def scim_group_response group
    group_data = {
      'schemas' => ['urn:scim:schemas:core:1.0'],
      'externalId' => group.name,
      'displayName' => group.name,
      'id' => group.guid,
      'members' => group.identities, #.collect {|i| ,
      'meta' => {
        'version' => 0,
        'created' => group.created_at.utc.strftime(UAA_DATE_FORMAT),
        'lastModified' => group.updated_at.utc.strftime(UAA_DATE_FORMAT),
      },
    }

    group_data.to_json
  end

  def handle_save_error group
    status((group.errors[:identifier] && group.errors[:identifier].any?{|e|e =~ /taken/}) ? 409 : 400)
    return  {
      :error => "invalid_#{group.class.name.underscore}",
      :error_description => group.errors.full_messages.join('. ')
    }.to_json
  end
end
