require 'bundler/setup'
require "yudu/version"
require "openssl"
require "base64"
require "pp"
require "httparty"
require "crack"

class Yudu
  class Error < StandardError; end
  include HTTParty
  include Crack


  parser(
    proc do |body, format|
      Crack::XML.parse(body)
    end
  )

  base_uri "https://api.yudu.com"

  def initialize(key, secret)
    @key = key
    @secret = secret
    @timestamp = Time.now.to_i
  end

  def sign_string(string, shared_secret)
    unless string && shared_secret
      raise 'Requires two arguments: String to be signed & shared secret.'
    end
    sha256 = OpenSSL::Digest::SHA256.new
    digest = OpenSSL::HMAC.digest(sha256, shared_secret, string)
    Base64.encode64(digest).chomp
  end

  def find_editions
    resource_path =  "/Yudu/services/2.0/editions/?timestamp=#{@timestamp}"
    signed_string = sign_string("GET#{resource_path}", @secret)
    @options = {
      headers: {
        "Authentication" => @key,
        "Signature" => signed_string
      }
    }
    self.class.get(resource_path, @options).parsed_response["editions"]["editionList"]
  end

  def find_edition(nodeId)
    unless nodeId
      raise 'Requires node ID to be provided.'
    end
    resource_path =  "/Yudu/services/2.0/editions/#{nodeId}?timestamp=#{@timestamp}"
    signed_string = sign_string("GET#{resource_path}", @secret)
    @options = {
      headers: {
        "Authentication" => @key,
        "Signature" => signed_string
      }
    }
    self.class.get(resource_path, @options).parsed_response["edition"]
  end

end

#editions = Yudu.new(key, secret)
#editions.find_editions 
#edition.find_editions("125911") #nodeId