class GroupsController < ApplicationController

        # XXX Test only methods:
        # Reset -- delete all users
        get '/RESET/' do
          Group.delete_all
          return
        end
        # TODO Move these to test-only class.

  # Create a Group
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#create-a-group-post-group
  post '/?' do
    raise Aok::Errors::NotImplemented
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

end
