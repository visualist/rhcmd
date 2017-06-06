#!/usr/bin/env ruby

require "uri"
require "net/http"


class CmsHook

  def initialize collection
    @base = 'http://cms.walkerart.org/' # removed :80
    @database = "webprod"
    @collection = collection
  end

  def request docid, action
    uri = URI.parse(@base)
    uri.query = URI.encode_www_form(getparams(docid, action))
    #uri
    Net::HTTP.get(uri)
  end

  private

  def getparams docid, action, verb=nil
    params = {
      "wrs_action"                        => "rest-notification",
      "wrs_rest_notification_action"      => action, # create, delete, update
      "wrs_rest_notification_collection"  => @collection,
      "wrs_rest_notification_document_id" => docid
    }
    # these fields are presently ignored by CMS..
    params["wrs_rest_notification_db"] = @database
    params["wrs_rest_notification_verb"] = verb unless verb.nil?
    params
  end

end


def submit verb, docpath, json=nil

  case verb.downcase.to_sym
    when :delete
      action = "delete"
    when :put
      action = "update"
    when :patch
      action = "update"
    else
      raise "cannot handle verb #{verb}"
  end

  parts = docpath.split('/')
  parts.shift # first is empty
  collection = parts[1]
  docid = parts[2]

  cmshook = CmsHook.new(collection)
  response = cmshook.request(docid, action)
  p response
end


file = ARGV.shift
if file.nil?
  $stderr.puts "need filename" 
  exit 1
else
  if !File.exists?(file)
    $stderr.puts "file not found: #{file}" 
    exit 2
  end
end


File.open(file, "r") do |f|
  f.readlines.each do |line|
    a = line.chomp.split
    submit(*a)
  end
end

