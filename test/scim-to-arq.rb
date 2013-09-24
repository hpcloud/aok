#!/usr/bin/env ruby

require 'test/unit'
require 'scim/scim'
require 'yaml'
require 'json'

class TestScimToArq < Test::Unit::TestCase
  def test_scim_to_arq
    parser = SCIM::Query::Filter::Parser.new
    $test_scim_to_arq_data.each do |test|
      input = test['scim'] or
        fail "No test input for #{test}"
      input.chomp!
      got_arq = Aok::Scim::ActiveRecordQueryBuilder.new.build_query(input)
      arq = test['arq'] or
        fail "No expected arq for: '#{input}'"
      got_arq_json = got_arq.to_json
      want_arq_json = arq.to_json
      assert_equal want_arq_json, got_arq_json,
        "Test parse to ActiveRecord: '#{input}'"
    end
  end
end

# See http://www.simplecloud.info/specs/draft-scim-api-01.html#query-resources
$test_scim_to_arq_data = YAML.load(<<'EOS')
- scim: userName eq "bjensen"
  arq: ['LOWER(username) = ?', bjensen]

- scim: name.familyName co "O'Malley"
  arq: ['LOWER(family_name) LIKE ?', "%o'malley%"]

- scim: userName sw "J"
  arq: ['LOWER(username) LIKE ?', 'j%']

- scim: title pr
  arq: [title IS NOT NULL]

- scim: meta.lastModified gt "2011-05-13T04:42:34Z"
  arq: ['updated_at > ?', '2011-05-13T04:42:34Z']

- scim: meta.lastModified ge "2011-05-13T04:42:34Z"
  arq: ['updated_at >= ?', '2011-05-13T04:42:34Z']

- scim: meta.lastModified lt "2011-05-13T04:42:34Z"
  arq: ['updated_at < ?', '2011-05-13T04:42:34Z']

- scim: meta.lastModified le "2011-05-13T04:42:34Z"
  arq: ['updated_at <= ?', '2011-05-13T04:42:34Z']

- scim: title pr and userType eq "Employee"
  arq: ['title IS NOT NULL AND LOWER(user_type) = ?', employee]

- scim: userType eq "Employee" and (emails co "example.com" or emails co "example.org")
  arq: ['LOWER(user_type) = ? AND (LOWER(email) LIKE ? OR LOWER(email) LIKE ?)', employee, "%example.com%", "%example.org%"]
EOS
