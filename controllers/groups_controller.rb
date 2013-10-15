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
    group = make_group read_json_body
    if group.save
      return 201, group_hash(group).to_json
    else
      handle_save_error group
    end
  end

  # Update a Group
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#update-a-group-patch-groupid
  patch '/:id' do
    raise Aok::Errors::NotImplemented
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
    raise Aok::Errors::NotImplemented
  end


  def make_group hash
    group = Group.new
    group.name = hash['displayName']
    return group
  end

  def group_hash group
    {
      :id => group.guid,
      :displayName => group.name,
    }
  end

  def handle_save_error group
    status((group.errors[:identifier] && group.errors[:identifier].any?{|e|e =~ /taken/}) ? 409 : 400)
    return  {
      :error => "invalid_#{group.class.name.underscore}",
      :error_description => group.errors.full_messages.join('. ')
    }.to_json
  end
end
