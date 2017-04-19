
require 'json'

database = "webprod"
tables = %w{artworks artpeople}
verb = "PATCH"


tables.each do |table|

  jsonfile = "#{table}-rels.json"
  metadata = `json_reformat -m < #{jsonfile}`.chomp
  puts "#{verb} /#{database}/#{table} #{metadata}"
end

