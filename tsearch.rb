#!/usr/bin/env ruby

# reference use-case for TableQuery class c. 6/01/2017

require_relative 'table_query'

options = {'filter' => '{content:{$regex:"(?i)http://blogs.walkerart.org.*"}}'}
tq = TableQuery.new "articles", options

ctr = 0
tq.each do |doc|
  id = doc["_id"]
  puts "#{ctr} => #{id}"
  ctr += 1
end

