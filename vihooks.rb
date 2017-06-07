#!/usr/bin/env ruby

#
# vihooks, Rev 1 : just generate the api bit (to stdout) in order to edit
#

require_relative 'config'
require_relative 'command'
require 'json'

tablename = ARGV.shift
if tablename.nil?
  $stderr.puts "Error: no table/collection provided"
  exit 1
end
database = "webprod"

if tablename.include?('/')
  parts = tablename.split('/').reject{|i| i.nil? || i.empty?}
  if parts.count != 2
    $stderr.puts "Error: confused by this arg: #{tablename}, looking for table name"
    exit 1
  end
  database = parts[0]
  tablename = parts[1]
end

tablepath_parts = [nil, database, tablename]
tablepath = tablepath_parts.join('/')
ARGV.push(tablepath)

options = {return_json: true}

begin
  answer = Command.get(ARGV, options)
rescue CommandException => e
  $stderr.puts "Error: #{e.message}"
  exit 1
end

hooks_data = JSON.parse(answer).select{|k,v| k=="hooks"}
hooks_json = JSON.pretty_generate(hooks_data)

puts "PATCH #{tablepath} \n#{hooks_json}"

