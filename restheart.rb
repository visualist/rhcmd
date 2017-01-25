module Restheart

  class Response
    attr_reader :code
    attr_reader :json

    def initialize(http_response)
      @code = http_response.code
      @json = http_response.body
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
      resource = _resource(path)
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

    private

    def _resource path
      resource_path = parse(path)
      RestClient::Resource.new(resource_path, @user, @password)
    end

    def parse path
      parts = path.split('/').reject{|i| i.nil? || i==''}
      resource = [@base_path]
      resource.concat(parts).join('/')
    end
  end

end
