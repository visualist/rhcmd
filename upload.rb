#!/usr/bin/env ruby

require_relative 'config'
require_relative 'command'
require 'optparse'

#options = {}
#OptionParser.new do |option|
#end.parse!

file = ARGV.shift
if !file.nil?
  raise "no file" if !File.exists?(file)
  options = {standalone: true, file_in: file}
else
  options = {standalone: true}
end

begin
  Command.up(ARGV, options)
rescue CommandException => e
  $stderr.puts "Error: #{e.message}"
  exit 1
end

