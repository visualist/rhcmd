
class ResourcePath

  attr_accessor :url, :path

  def initialize path, cfg = Config
    @base_url = "#{cfg.protocol}://#{cfg.host}:#{cfg.port}"
    @path = make_path_for(path)
    @url = "#{@base_url}#{@path}"
  end

  def what
    path_components = path.split('/').reject(&:empty?)
    n = path_components.count
    return :root if n==0
    return :db   if n==1
    return :col  if n==2
    return :doc  if n==3
    return :unknown
  end

  private

  def make_path_for path
    return '/' if path.nil?
    path_components = path.split('/')
    path_components.delete_if{|c| c.nil? || c.empty?}.unshift('')
    path_components.join('/')
  end

end

