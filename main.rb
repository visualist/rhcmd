#!/usr/bin/env ruby

require_relative 'config'
require_relative 'command'
require 'optparse'

options = {}
OptionParser.new do |option|
  option.on('-i', '--input FILE', 'Read from file') {|o| options[:file_in] = o}
  option.on('-o', '--output FILE', 'Write to file') {|o| options[:file_out] = o}
end.parse!

cmd = ARGV.shift || "help"
cmd_s = cmd.to_sym
if Command.available_command(cmd_s)
  Command.send(cmd_s, ARGV, options)
else
  puts "Unrecognized subcommand: #{cmd}"
  exit(1)
end

