#!/usr/bin/env ruby

require_relative 'config'
require_relative 'command'
require 'optparse'

options = {}
OptionParser.new do |option|
  option.on('-i', '--input FILE', 'Read from file') {|o| options[:file_in] = o}
  option.on('-o', '--output FILE', 'Write to file') {|o| options[:file_out] = o}

  # Note: all-option will override page number for 'ls'
  option.on('-a', '--all', 'Request all objects for ls') do
    options[:all] = true
  end

  option.on('-p', '--page page_number', 'Request page number') do |o|
    options[:page_number] = o
  end

  option.on('-f', '--hal-mode', 'HAL full mode') do
    options[:hal_full] = true
  end
  option.on('-j', '--json', 'Output JSON') do
    options[:json] = true
  end
  option.on('-l', '--long', 'Long form output') do
    options[:long] = true
  end
# option.on('-d', '--download', 'download option') do
#   options[:custom] = true
# end
  option.on('-c', '--custom', 'specialized output with ls') do
    options[:custom] = true
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

