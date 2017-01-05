
class ResourcePath

  attr_accessor :url, :path

  def initialize path, cfg = Config
    @base_url = "#{cfg.protocol}://#{cfg.host}:#{cfg.port}"
    @path = make_path_for(path)
    @url = "#{@base_url}#{@path}"
  end

  private

  def make_path_for path
    return '/' if path.nil?
    path_components = path.split('/')
    path_components.delete_if{|c| c.nil? || c.empty?}.unshift('')
    path_components.join('/')
  end

end

