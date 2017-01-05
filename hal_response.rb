class HalResponse

  attr_accessor :data, :valid, :type, :embed_key

  def initialize json_body, options
    @options = options
    @data = JSON.parse(json_body)
    @valid = @data.has_key?('_embedded')
    if @valid
      @embed_key = @data['_embedded'].keys.first # probably bad assumption, long term
      @type = @embed_key.gsub(/^rh:/, '')
    else
      @embed_key = nil
      @type = nil
      @valid = false
    end
  end

  def loop prefix
    prefix = '' if prefix=='/'
    get_items.each do |item|
      id = item['_id']
      if id.is_a?(Hash) && id.has_key?('$oid')
        id = id['$oid']
        keys = item.keys.reject{|i| i=~/^_/}.sort.join(', ')
        desc = "#{keys}"
      else
        desc = item['desc']
      end
      etag = item['_etag']['$oid']
      if @options[:long]
        puts "#{prefix}/#{id}  #{etag}  \"#{desc}\""
      else
        puts "#{prefix}/#{id}"
      end
    end
  end

  private

  def get_items
    @data['_embedded'][@embed_key]
  end

end
