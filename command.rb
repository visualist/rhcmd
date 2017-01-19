require 'rest-client'
require 'json'

require_relative 'resource_path'
require_relative 'hal_response'

module Command

  Available_commands = %w{ls get info help config}.map(&:to_sym)

  def self.available_command subcmd
    Available_commands.include?(subcmd.to_sym)
  end

  def self.help args, options
    commands = Available_commands.map{|i| i.to_s}.join(' ')
    puts "Available commands: #{commands}"
  end

  def self.info args, options
    config args, options
  end

  def self.config args, options
    puts "Configuration for #{ENV['RHCMD_ENV']}:"
    Config.each_pair do |k,v|
      puts "  #{k} = #{v}"
    end
    puts "Args: #{args}"
    puts "Opts: #{options}"
  end

  def self.ls args, options
    rp = ResourcePath.new(args.first)
    puts "URL: #{rp.url}" unless options[:json] if options[:long]
    resource = RestClient::Resource.new(rp.url, Config.user, Config.password)

    params = {'count' => true} # probably doesn't do much good for an 'ls'
    params['hal'] = 'f' if options[:hal_full]
    params['page'] = options[:page_number] if options[:page_number]

    begin
      response = resource.get(params: params)
    rescue RestClient::NotFound
      puts "#{rp.path}: No such resource"
      return
    end

    if options[:json]
      puts response.body # response should already be in JSON
    else
      rh = HalResponse.new(response.body, options)
      rh.loop(rp.path) if rh.valid
    end
  end

  def self.get args, options
    rp = ResourcePath.new(args.first)
    puts "URL: #{rp.url}" unless options[:json] if options[:long]
    resource = RestClient::Resource.new(rp.url, Config.user, Config.password)

    params = {'count' => true}
    params = {'hal' => 'f'} if options[:hal_full]
    params['page'] = options[:page_number] if options[:page_number]

    begin
      response = resource.get(params: params)
    rescue RestClient::NotFound
      puts "#{rp.path}: No such resource"
      return
    end
    puts response.body
  end

end
