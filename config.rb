
require 'yaml'
require 'ostruct'
require 'erb'

env = ENV["RHCMD_ENV"] || "development"
yaml = YAML::load(File.open("config/restheart.yml"))[env]

cfg = yaml.each_with_object({}){|(k, v), hash| hash[k] = ERB.new(v).result}
Config = OpenStruct.new(cfg)

