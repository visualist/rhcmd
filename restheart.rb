module Restheart

  class ResponseCode
    attr_reader :code

    def initialize(code)
      @code = code
      @json = nil
    end

    def data
      nil
    end
  end

  class Response
    attr_reader :code, :json

    def initialize(http_response)
      @code = http_response.code
      @json = http_response.body # assumes JSON!
    end

    def data
      JSON.parse(@json)
    end
  end


  class Connection
    def initialize cfg
      @base_path = "#{cfg.protocol}://#{cfg.host}:#{cfg.port}"
      @user = cfg.user
      @password = cfg.password
      #@content_type = "application/hal+json"
      @content_type = "application/json"
    end

    def get path, params={}
      resource = client_resource(path)
      begin
        http_response = resource.get(params: params)
        response = Restheart::Response.new(http_response)

      rescue RestClient::NotFound
        $stderr.puts "(get) Not Found: #{path}"
        response = nil

      rescue RestClient::BadRequest
        $stderr.puts "(get) BadRequest: #{path}"
        response = nil
      end
      response
    end


    def delete path, headers
      resource = client_resource(path)
      begin
        response = resource.delete(headers)
      rescue Exception => e
        $stderr.puts "EXCEPTION: #{e.inspect}"
      end
      response
    end


    def post path, attributes, etag=nil
      _write(:post, path, attributes, etag)
    end

    def put path, attributes, etag=nil
      _write(:put, path, attributes, etag)
    end


    def patch path, attributes, etag=nil
      _write(:patch, path, attributes, etag)
    end


    private

    def _cleanse attributes
      # RH will 406 on attempts at writing _etag or _id
      # RH will silently ignore anything else with a leading _
      attributes.reject{|k,v| k =~ /^_/ || k.to_sym=='id'}
    end

    def _write method, path, attributes, etag
      resource = client_resource(path)
      atr = _cleanse(attributes).to_json

      headers = { :content_type => @content_type,
                  :accept => "application/json, */*" }

      method_name = method.to_s
      begin
        http_response = resource.send(method, atr, headers)
        response = Restheart::Response.new(http_response)
        response_code = response.code

      rescue RestClient::NotFound => e
        $stderr.puts "(#{method_name}) Not Found: #{path}"
        response_code = e.http_code

      rescue RestClient::BadRequest => e
        $stderr.puts "(#{method_name}) Bad Request: #{path}"
        response_code = e.http_code

      rescue RestClient::NotAcceptable => e
        $stderr.puts "(#{method_name}) Not Acceptable: #{path}"
        response_code = e.http_code

      rescue RestClient::PreconditionFailed => e
        $stderr.puts "(#{method_name}) Not Acceptable: #{path}"
        $stderr.puts "    #{response.inspect}"
        response_code = e.http_code

      end
      response_code
    end

    def client_resource path
      resource_path = _parse(path)
      RestClient::Resource.new(resource_path, @user, @password)
    end

    def _parse path
      parts = path.split('/').reject{|i| i.nil? || i==''}
      resource = [@base_path]
      resource.concat(parts).join('/')
    end
  end

end
