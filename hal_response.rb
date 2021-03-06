class HalResponse

  attr_accessor :data, :valid, :type, :embed_key

  def initialize json_body, options
    @json_body = json_body
    @options = options
    @data = JSON.parse(@json_body)
    @valid = @data.has_key?('_embedded')
    if @valid
      embed = @data['_embedded']
      case embed
        when Array
          @embed_key = nil # is there something else we can look at?
          @items = embed
        when Hash
          @embed_key = @data['_embedded'].keys.first
          @items = embed[@embed_key]
        else
          @embed_key = nil
          @items = nil
      end
      #@type = @embed_key.gsub(/^rh:/, '') unless @embed_key.nil?
    else
      @embed_key = nil
      @valid = false
    end
    if @data.has_key?('_type')
      @type = @data['_type'] # ROOT, DB, COLLECTION, DOCUMENT (as a string)
    else
      @type = nil
    end
  end

  def loop prefix
    prefix = '' if prefix=='/'
    get_items.each do |item|
      id = item['_id']

      if item.has_key?('desc')
        desc = item['desc']

      elsif id.is_a?(Hash) && id.has_key?('$oid')
        id = id['$oid']
        keys = item.keys.reject{|i| i=~/^_/}.sort.join(', ')
        desc = "#{keys}"

      else
        keys = item.keys.reject{|i| i=~/^_/}.sort.join(', ')
        desc = "#{keys}"
      end

      etag = item.has_key?('_etag') ? item['_etag']['$oid'] : ''
      if @options[:long]
        puts "#{prefix}/#{id}  #{etag}  \"#{desc}\""

      elsif @options[:download]
        puts "#{prefix}/#{id},#{item.to_json}"

      elsif @options[:custom]
        #puts "#{prefix}/#{id} #{item['artmedia_id']}"
        puts "#{prefix}/#{id},#{item['artmedia_id']}"
        #puts "#{prefix}/#{id} #{item}"
      else
        puts "#{prefix}/#{id}"
      end
    end
  end

  def meta
    desired_keys = %w{ _id desc _etag _size _total_pages
                       _returned _type _lastupdated_on }
    @data.select{|k,v| desired_keys.include?(k)}
  end

  def self_link
    return @data['_links']['self']['href'] if @data['_links'] && @data['_links']['self']
    nil
  end

  def first_link
    return @data['_links']['first']['href'] if @data['_links'] && @data['_links']['first']
    nil
  end

  def last_link
    return @data['_links']['last']['href'] if @data['_links'] && @data['_links']['last']
    nil
  end

  def next_link
    return @data['_links']['next']['href'] if @data['_links'] && @data['_links']['next']
    nil
  end

  def previous_link
    return @data['_links']['previous']['href'] if @data['_links'] && @data['_links']['previous']
  end

  private

  def get_items
    @items
  end

end
