require 'json'
require 'activesupport'   # for Time.parse, unfortunately

require File.dirname(__FILE__) + '/../vendor/maruku/maruku'

$LOAD_PATH.unshift File.dirname(__FILE__) + '/../vendor/syntax'
require 'syntax/convertors/html'

class Post
	def self.attrs
		[ :slug, :title, :body, :tags, :created_at ]
	end

	def attrs
		self.class.attrs.inject({}) do |a, key|
			a[key] = send(key)
			a
		end
	end

	attr_accessor *attrs

	def created_at=(t)
		@created_at = t.is_a?(Time) ? t : Time.parse(t)
	end

	def initialize(params={})
		params.each do |key, value|
			send("#{key}=", value)
		end
	end

	class RecordNotFound < RuntimeError; end

	def self.find_by_slug(slug)
		json = DB[new(:slug => slug).db_key]
		raise RecordNotFound unless json
		new JSON.parse(json)
	end

	def self.find_range(start, len)
		DB.list_range(chrono_key, start, start + len - 1).map do |slug|
			find_by_slug(slug)
		end
	end

	def self.all
		find_range(0, 9999999)
	end

	def db_key
		"#{self.class}:slug:#{slug}"
	end

	def self.chrono_key
		"#{self}:chrono"
	end

	def save
		DB[db_key] = attrs.to_json
	end

	def self.create(params)
		post = new(params)
		post.save
		DB.push_head(chrono_key, post.slug)
		post
	end

	def destroy
		DB.list_rm(self.class.chrono_key, db_key, 0)
		DB.delete(db_key)
	end

	def self.destroy_all
		all.each do |post|
			post.destroy
		end
	end

	############

	def url
		d = created_at
		"/past/#{d.year}/#{d.month}/#{d.day}/#{slug}/"
	end

	def full_url
		Blog.url_base.gsub(/\/$/, '') + url
	end

	def body_html
		to_html(body)
	end

	def summary
		@summary ||= body.match(/(.{200}.*?\n)/m)
		@summary || body
	end

	def summary_html
		to_html(summary.to_s)
	end

	def more?
		@more ||= body.match(/.{200}.*?\n(.*)/m)
		@more
	end

	def linked_tags
		tags.split.inject([]) do |accum, tag|
			accum << "<a href=\"/past/tags/#{tag}\">#{tag}</a>"
		end.join(" ")
	end

	def self.make_slug(title)
		title.downcase.gsub(/ /, '_').gsub(/[^a-z0-9_]/, '').squeeze('_')
	end

	########

	def to_html(markdown)
		h = Maruku.new(markdown).to_html
		h.gsub(/<code>([^<]+)<\/code>/m) do
			convertor = Syntax::Convertors::HTML.for_syntax "ruby"
			highlighted = convertor.convert($1)
			"<code>#{highlighted}</code>"
		end
	end

	def split_content(string)
		parts = string.gsub(/\r/, '').split("\n\n")
		show = []
		hide = []
		parts.each do |part|
			if show.join.length < 100
				show << part
			else
				hide << part
			end
		end
		[ to_html(show.join("\n\n")), hide.size > 0 ]
	end
end
