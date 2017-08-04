#!/usr/bin/env ruby

require_relative 'config'
require_relative 'command'

file = ARGV.shift
if !file.nil?
  raise "no file" if !File.exists?(file)
  options = {standalone: true, testrun: true, file_in: file}
else
  options = {standalone: true, testrun: true}
end

begin
  Command.up(ARGV, options)
rescue CommandException => e
  $stderr.puts "Error: #{e.message}"
  exit 1
end

