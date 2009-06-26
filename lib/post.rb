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

	def self.new_from_json(json)
		raise RecordNotFound unless json
		new JSON.parse(json)
	end

	def self.new_from_slugs(slugs)
		ids = slugs.map { |slug| db_key_for_slug(slug) }
		DB.mget(ids).map { |json| new_from_json(json) }
	end

	def self.find_by_slug(slug)
		new_from_json DB[db_key_for_slug(slug)]
	end

	def self.find_range(start, len)
		new_from_slugs DB.list_range(chrono_key, start, start + len - 1)
	end

	def self.all
		find_range(0, 9999999)
	end

	def self.find_tagged(tag)
		new_from_slugs DB.list_range("#{self}:tagged:#{tag}", 0, 99999)
	end

	def self.db_key_for_slug(slug)
		"#{self}:slug:#{slug}"
	end

	def db_key
		self.class.db_key_for_slug(slug)
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
		post.build_indexes
		post
	end

	def build_indexes
		DB.push_head(self.class.chrono_key, slug)

		tags.split.each do |tag|
			DB.push_head("#{self.class}:tagged:#{tag}", slug)
		end
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
