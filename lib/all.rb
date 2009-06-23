require 'json'
require 'ostruct'
require 'active_support/core_ext/time'

require 'redis'

redis_config = if ENV['REDIS_URL']
	require 'uri'
	uri = URI.parse ENV['REDIS_URL']
	{ :host => uri.host, :port => uri.port, :password => uri.password, :db => uri.path.gsub(/^\//, '') }
else
	{}
end

DB = Redis.new(redis_config)

require File.dirname(__FILE__) + '/../vendor/maruku/maruku'

$LOAD_PATH.unshift File.dirname(__FILE__) + '/../vendor/syntax'
require 'syntax/convertors/html'

$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'post'
