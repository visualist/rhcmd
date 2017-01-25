
#
# TODO:
#  Notes to self: presently there is a mixture of direct calls
#  to RestClient, and indirect ones through the Restheart set
#  of classes. The goal is to move completely to Restheart.
#

require 'rest-client'
require 'json'

require_relative 'resource_path'
require_relative 'hal_response'
require_relative 'restheart'

class CommandException < Exception; end

module Command

  # ls  - listing
  # get - get an individual object (db, table, doc)
  # dl  - download (objects in a collection)
  # up  - upload (objects into a collection)
  # cr  - create object (db, table, doc)
  # info help config 

  Available_commands = %w{ls get dl up cr rm info help config}.map(&:to_sym)

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

  # Remove - destructive command!
  def self.rm args, options
    rp = ResourcePath.new(args.first)
    puts "URL: #{rp.url}" unless options[:json] if options[:long]
    rh = Restheart::Connection.new(Config)

    params = {}
    #params = {'hal' => 'f'} if options[:hal_full]
    #params['page'] = options[:page_number] if options[:page_number]

    rresponse = rh.get(rp.path, params)
    etag = rresponse.data['_etag']['$oid']

    headers = {}
    headers.merge!({'If-Match' => etag})

    rresponse = rh.delete(rp.path, headers)
    puts rresponse
  end

  def self.cr args, options
    rp = ResourcePath.new(args.first)
    resource = RestClient::Resource.new(rp.url, Config.user, Config.password)
    attributes = {} # TODO: eventually provide a means to put data here
    payload = attributes.to_json
    headers = { :content_type => "application/json",
                :accept => "application/json, */*" }
    begin
      response = resource.get()
      etag = JSON.parse(response.body)["_etag"]["$oid"]
      headers.merge!({'If-Match' => etag})
      response = resource.patch(payload, headers)
      puts "PATCH #{rp.path}" if options[:verbose]

    rescue RestClient::NotFound
      response = resource.put(payload, headers)
      puts "PUT #{rp.path}" if options[:verbose]
    end
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

  def self.up args, options
    raise CommandException.new("input file required") unless options[:file_in]
    rp = ResourcePath.new(args.first)
    raise CommandException.new("target collection/table required") unless rp.what==:col
    infile = options[:file_in]
    File.readlines(infile).each do |line|
      path, json = line.split(',', 2)
      path_components = path.split('/').reject(&:empty?)
      db, tbl, doc = path_components
      if path_components.count==3
        docpath = "#{rp.path}/#{doc}"
        rh_submit(docpath, JSON.parse(json))
      end
    end
  end

  def self.rh_submit docpath, jsondata
    params = jsondata.reject{|k,v| k =~ /^_/ || k.to_sym=='id'}
    rh = Restheart::Connection.new(Config)
    rp = ResourcePath.new(docpath)
    rresponse = rh.put(rp.path, params)
    puts "PUT #{docpath} #{params} --> #{rresponse.inspect}"
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
    rh = Restheart::Connection.new(Config)

    params = {'count' => true}
    params = {'hal' => 'f'} if options[:hal_full]
    params['page'] = options[:page_number] if options[:page_number]

    rresponse = rh.get(rp.path, params)
    puts rresponse.json
  end

end
