
require 'json'
require_relative 'config'
require_relative 'command'


class TableQuery

  attr_reader :params
  attr_reader :tablepath
  attr_reader :page
  attr_reader :response_json
  attr_reader :response
  attr_reader :size
  attr_reader :total_pages
  attr_reader :returned
  attr_reader :documents
  attr_reader :current

  def initialize table, options, db="webprod"
    @tablepath = [nil, db, table].join('/')
    @rh = Restheart::Connection.new(Config)
    @rp = ResourcePath.new(@tablepath)
    @params = {'count' => true, 'hal' => 'f'}.merge(options)
    @page = 0
    @position = 0
    @returned = 0
    @response = {}
    @current = ""
    get_next_page # need to prime it, to get the @size and other params
  end

  def get
    @current
  end

  def next
    get_next_page if need_next_page?
    @current = @documents[@position]
    @position += 1
    @current
  end

  def each
    for i in 0...@size
      yield self.next  # future TODO: arbitrary [i] indexing
    end
  end

  private

  def need_next_page?
    @position >= @returned
  end

  def get_next_page
    @page += 1
    @position = 0
    $stderr.puts "get page #{@page}"
    get_set
  end

  def get_set
    @params['page'] = @page
    rresponse = @rh.get(@rp.path, @params)
    @response_code = rresponse.code
    @response_json = rresponse.json
    @response = JSON.parse(@response_json)
    raise "error: expected a collection" unless @response["_type"]=='COLLECTION'
    @size = @response['_size']
    @total_pages = @response["_total_pages"]
    @returned = @response["_returned"]
    @documents = @response["_embedded"]["rh:doc"]
  end

end

