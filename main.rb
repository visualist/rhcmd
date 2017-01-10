#!/usr/bin/env ruby

require_relative 'config'
require_relative 'command'
require 'optparse'

options = {}
OptionParser.new do |option|
  option.on('-i', '--input FILE', 'Read from file') {|o| options[:file_in] = o}
  option.on('-o', '--output FILE', 'Write to file') {|o| options[:file_out] = o}
  option.on('-f', '--hal-mode', 'HAL full mode') do
    options[:hal_full] = true
  end
  option.on('-j', '--json', 'Output JSON') do
    options[:json] = true
  end
  option.on('-l', '--long', 'Long form output') do
    options[:long] = true
  end
end.parse!

cmd = ARGV.shift || "help"
cmd_s = cmd.to_sym
if Command.available_command(cmd_s)
  Command.send(cmd_s, ARGV, options)
else
  puts "Unrecognized subcommand: #{cmd}"
  exit(1)
end

