module UserHelper
  MAX_ITEMS_PER_PAGE = 1000
  DEFAULT_ITEMS_PER_PAGE = 100
  VALID_ATTRIBUTES = %W{id name userName emails groups externalId}.collect(&:downcase)

  # query_users_as_scim returns a scim user listing performing filtering if provided.
  # http://www.simplecloud.info/specs/draft-scim-api-01.html#query-resources
  # http://tools.ietf.org/html/draft-ietf-scim-core-schema-02#section-12
  def query_users_as_scim(filter, params = {})
    filter = true if filter.blank? || filter =='""' #XXX bug in scim-query-filter-parser-rb
    start_index = params[:startIndex] || 1
    start_index = [start_index.to_i, 1].max
    items_per_page = params[:count] || DEFAULT_ITEMS_PER_PAGE
    items_per_page = [items_per_page.to_i, MAX_ITEMS_PER_PAGE].min
    identities = Identity.
        where(filter).
        includes(:groups =>[:parent_groups]).
        limit(items_per_page).
        offset(start_index - 1)
    resources = []

    identities.each_with_index do |identity, index|
      resources.push(user_hash(identity, attributes))
    end

    {
        'totalResults' => Identity.where(filter).count,
        'itemsPerPage' => items_per_page,
        'startIndex' => start_index,
        'schemas' => ["urn:scim:schemas:core:1.0"],
        'resources' => resources,
    }
  end

  def attributes
    return nil unless params[:attributes]
    attrs = params[:attributes].downcase.split(',')

    attrs & VALID_ATTRIBUTES
  end

  def user_hash user, attrs = nil
    attrs ||= VALID_ATTRIBUTES
    user_data = {
        'schemas' => ['urn:scim:schemas:core:1.0']
    }
    user_data['externalId'] = user.username if attrs.include?('externalid')
    user_data['id'] = user.guid if attrs.include?('id')
    user_data['meta'] = {
        'version' => user.version,
        'created' => user.created_at.utc.strftime(UAA_DATE_FORMAT),
        'lastModified' => user.updated_at.utc.strftime(UAA_DATE_FORMAT),
    }

    f = user.family_name
    g = user.given_name
    if (f or g) && attrs.include?('name')
      n = user_data['name'] = {}
      n['familyName'] = f if f
      n['givenName'] = g if g
    end
    user_data['userName'] = user.username if attrs.include?('username')
    user_data["emails"] = [
        {"value" => user.email}
    ] if attrs.include?('emails')
    if attrs.include?('groups')
      user_data['groups'] = user.ascendant_groups.collect do |group|
        {
            'display' => group.name,
            'value' => group.guid
        }
      end
    end

    user_data
  end
end
