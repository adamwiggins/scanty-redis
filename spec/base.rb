require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../lib/all'

Blog = OpenStruct.new(
	:title => 'My blog',
	:author => 'Anonymous Coward',
	:url_base => 'http://blog.example.com/'
)
