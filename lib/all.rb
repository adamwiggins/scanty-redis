require 'json'
require 'ostruct'
require 'active_support/core_ext/time'

require 'redis'
DB = Redis.new

require File.dirname(__FILE__) + '/../vendor/maruku/maruku'

$LOAD_PATH.unshift File.dirname(__FILE__) + '/../vendor/syntax'
require 'syntax/convertors/html'

$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'post'
