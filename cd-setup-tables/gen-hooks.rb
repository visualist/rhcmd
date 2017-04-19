
require 'json'


metadata = {
  "hooks" => [
    {
      "name": "notify",
      "args": [
        "http://prd-cms.walkerart.org:80/"
      ]
    }
  ]
}.to_json


database = "webprod"
tables = %w{artworks artpeople artmedia}
verb = "PATCH"

tables.each do |table|

  puts "#{verb} /#{database}/#{table} #{metadata}"
end

