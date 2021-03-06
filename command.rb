
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

  Available_commands = %w{ls get size dl up cr rm info help config}.map(&:to_sym)

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
    linenumber = 0

    if options.has_key?(:standalone) && options[:standalone]
      if options.has_key?(:file_in) && !options[:file_in].empty?
        infile = options[:file_in]
        contents = File.readlines(infile)
      else
        contents = $stdin
      end

    else
      #puts "infile: #{infile}"
      raise CommandException.new("input file required") unless options[:file_in]
      rp = ResourcePath.new(args.first)
      raise CommandException.new("target collection/table required") unless rp.what==:col
      infile = options[:file_in]
      contents = File.readlines(infile)
    end

    if options.has_key?(:testrun)
      $stderr.puts "TESTRUN ONLY - no changes will be made"
    end

    contents.each do |line|
      linenumber += 1

      if line =~ /^[PM]/i
        verb, path, json = line.split(' ', 3)
        verb.downcase!
        if verb!="put" && verb!="patch" && verb!="merge" && verb!="post"
          why = "verb #{verb} not supported"
          skip = "skipping line #{linenumber}"
          truncated_text = line.gsub(/^(.{40,}?).*$/m, '\1')
          $stderr.puts "Warning: #{why}, #{skip}: #{truncated_text}..."
          next
        end

      elsif line =~ /^D/i
        #delete
        verb, path, json = line.split(' ', 3)
        json = '{}'
        verb.downcase!
        if verb!="delete"
          why = "verb #{verb} not supported"
          skip = "skipping line #{linenumber}"
          truncated_text = line.gsub(/^(.{40,}?).*$/m, '\1')
          $stderr.puts "Warning: #{why}, #{skip}: #{truncated_text}..."
          next
        end

      elsif line =~ /^\//
        path, json = line.split(',', 2)
        verb = "put"

      elsif line =~ /^\s*#/ || line =~ /^\s*$/
        # skip comments and blank lines
        next

      else
        why = "line not parsed"
        skip = "skipping line #{linenumber}"
        truncated_text = line.gsub(/^(.{50,}?).*$/m, '\1')
        $stderr.puts "Warning: #{why}, #{skip}: #{truncated_text}..."
        next
      end

      path_components = path.split('/').reject(&:empty?)

      # TODO: generalize this: allow override path-component by component
      db, tbl, doc = path_components # this line might become obsolete!
      if path_components.count==3 && options[:target]
          # Overrides file-specified /db/col, uses cmd-line param
          docpath = "#{rp.path}/#{doc}"

        else
          # Uses the file-specified object /db/col/doc or whatever
          docpath = "/#{path_components.join('/')}"
      end
      result = rh_submit(verb.to_sym, docpath, JSON.parse(json), options)
      result = nil if options.include?(:testrun)
      throttle_if_needed(result)
    end
  end

  def self.rh_submit verb, docpath, jsondata, options={}
    verbose = 1   # 0, 1, 2
    params = jsondata.reject{|k,v| k =~ /^_/ || k.to_sym=='id'}
    rh = Restheart::Connection.new(Config)
    rp = ResourcePath.new(docpath)
    mergetxt = ""
    if verb == :merge
      mergetxt = "MERGE:"
      old_attributes = get_attributes(rh, rp.path)
      verb, params = compare_attributes(old_attributes, params)
    end
    if options.include?(:testrun)
      rresponse = "N/A"
    else
      begin
        rresponse = rh.send(verb, rp.path, params)
      rescue RestClient::Exceptions::ReadTimeout
        $stderr.puts "RestClient::Exceptions::ReadTimeout - skipped #{rp.path}"
      end
    end
    if verbose > 1
      $stderr.puts "#{mergetxt}#{verb.to_s.upcase} #{docpath} #{params} --> #{rresponse.inspect}"
    elsif (verbose > 0) and verb.to_s.upcase!="NOOP"
      $stderr.puts "#{mergetxt}#{verb.to_s.upcase} #{docpath} #{params} --> #{rresponse.inspect}"
    end
    {verb: verb}
  end

  def self.throttle_if_needed options
    return if options.nil?
    return if options[:verb].nil?
    verb_used = options[:verb]

    case verb_used
      when :noop
        # $stderr.puts "noop - no sleep"
        return

      when :patch
        $stderr.puts "patch - sleep 1"
        sleep(1)

      when :put
        $stderr.puts "put - sleep 3"
        sleep(3)
    end
  end

  def self.get_attributes rh, path
    response = rh.get(path)
    attrs = {}
    if !response.nil? && response.code==200
      attrs = JSON.parse(response.json).reject{|k,v| k =~ /^_/}
    end
    attrs
  end

  def self.compare_attributes old_attr, new_attr
    return [:noop, nil] if old_attr == new_attr # == requires Ruby2.3+

    diff_in_old = old_attr.reject{|k,v| new_attr[k] == v}
    diff_in_new = new_attr.reject{|k,v| old_attr[k] == v}
    missing = (diff_in_old.keys - diff_in_new.keys)
    added = (diff_in_new.keys - diff_in_old.keys)

    return [:put, new_attr] if old_attr.keys.count == 0
    return [:patch, diff_in_new] if (added.count >= 0) && (missing.count == 0)
    [:put, new_attr]
  end

  def self.getlist rp, resource, params, options
    begin
      response = resource.get(params: params)

    rescue Errno::ECONNREFUSED
      $stderr.puts "Connection refused, check config?"
      return nil

    rescue RestClient::NotFound
      $stderr.puts "#{rp.path}: No such resource"
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

  def self.size args, options
    rp = ResourcePath.new(args.first)
    puts "URL: #{rp.url}" unless options[:json] if options[:long]
    rh = Restheart::Connection.new(Config)
    params = {'count' => true, 'hal' => 'f'}
    rresponse = rh.get(rp.path, params)
    return nil if rresponse.nil?
    code = rresponse.code
    data = JSON.parse(rresponse.json)
    size = data['_size']
    if code==200 && !size.nil?
      puts size
    end
  end

  def self.get args, options
    rp = ResourcePath.new(args.first)
    puts "URL: #{rp.url}" unless options[:json] if options[:long]
    rh = Restheart::Connection.new(Config)

    params = {'count' => true}
    params['hal'] = 'f' if options[:hal_full]
    params['page'] = options[:page_number] if options[:page_number]

    rresponse = rh.get(rp.path, params)
    return rresponse.json if options[:return_json]
    puts rresponse.json
  end

end
