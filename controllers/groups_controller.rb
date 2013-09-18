class GroupsController < ApplicationController

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
    raise Aok::Errors::NotImplemented
  end

  # Delete a Group
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#delete-a-group-delete-groupid
  delete '/:id' do
    raise Aok::Errors::NotImplemented
  end

end