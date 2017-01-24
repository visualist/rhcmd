require 'rest-client'
require 'json'

require_relative 'resource_path'
require_relative 'hal_response'

module Command

  Available_commands = %w{ls get dl info help config}.map(&:to_sym)

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
    # hal-full is also needed for the 'all' option: provides the 'next' link
    params['hal'] = 'f' if options[:hal_full] || options[:all]
    params['page'] = options[:page_number] if options[:page_number]

    if options[:all]
      page = 1
      loop do
        params['page'] = page
        nxt = getlist(rp, resource, params, options)
        break if nxt.nil?
        page += 1
      end
    else
      getlist(rp, resource, params, options)
    end
  end

  def self.dl args, options
    rp = ResourcePath.new(args.first)
    #puts "URL: #{rp.url}" unless options[:json] if options[:long]
    resource = RestClient::Resource.new(rp.url, Config.user, Config.password)
    options.merge!({download: true})

    params = {'count' => true}
    params['hal'] = 'f'

    page = 1
    loop do
      params['page'] = page
      nxt = getlist(rp, resource, params, options)
      break if nxt.nil?
      page += 1
    end
  end

  def self.getlist rp, resource, params, options
    begin
      response = resource.get(params: params)
    rescue RestClient::NotFound
      puts "#{rp.path}: No such resource"
      return nil
    end

    if options[:json]
      puts response.body # response should already be in JSON
      return nil
    else
      rh = HalResponse.new(response.body, options)
      rh.loop(rp.path) if rh.valid
      return rh.next_link
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
