#!/usr/bin/env ruby

# reference use-case for TableQuery class c. 6/01/2017

require 'json'
require 'nokogiri'
require_relative 'table_query'

expression = '{content:{$regex:"(?i)src=.http://blogs.walkerart.org.*"}}'
# expression = '{content: { $regex: /src=.http.*blogs.walkerart.org.*/i }}'

options = {'filter' => expression}
tq = TableQuery.new "articles", options

def show doc
  fragment = Nokogiri::HTML.fragment(doc["content"])
  img_elements = fragment.search('img')
  puts "@#{img_elements.count} #{doc['_id']}: #{doc["title"]}"
  img_elements.each do |img|
    puts img['src']
  end
end


# $stderr.puts tq.size
tq.each do |doc|
  show(doc)
end



exit

ctr = 0
tq.each do |doc|
  id = doc["_id"]
  puts "#{ctr} => #{id}"
  ctr += 1
end

