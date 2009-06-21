require File.dirname(__FILE__) + '/base'

describe Post do
	before do
		@post = Post.new
	end

	it "has a list of attributes like slug and title" do
		Post.attrs.include?(:slug).should be_true
		Post.attrs.include?(:title).should be_true
	end

	it "can read and write to the the slug attr" do
		@post.slug = 'x'
		@post.slug.should == 'x'
	end

	it "attrs returns a hash of the current object attributes" do
		Post.new(:title => 'xyz').attrs[:title].should == 'xyz'
	end

	it "db key is of the format Post:slug:my-slug" do
		@post.slug = 'my-slug'
		@post.db_key.should == "Post:slug:my-slug"
	end

	it "saves to the db by serializing the attributes to json" do
		@post.slug = 'abc'
		Post.stub!(:attrs).and_return([ :slug ])
		DB.should_receive(:[]=).with('Post:slug:abc', '{"slug":"abc"}')
		@post.save
	end

	it "finds a post by slug" do
		DB.should_receive(:[]).with('Post:slug:abc').and_return('{"slug":"abc"}')
		Post.find_by_slug('abc').slug.should == 'abc'
	end

=begin
	it "has a url in simplelog format: /past/2008/10/17/my_post/" do
		@post.created_at = '2008-10-22'
		@post.slug = "my_post"
		@post.url.should == '/past/2008/10/22/my_post/'
	end

	it "has a full url including the Blog.url_base" do
		@post.created_at = '2008-10-22'
		@post.slug = "my_post"
		Blog.stub!(:url_base).and_return('http://blog.example.com/')
		@post.full_url.should == 'http://blog.example.com/past/2008/10/22/my_post/'
	end

	it "produces html from the markdown body" do
		@post.body = "* Bullet"
		@post.body_html.should == "<ul>\n<li>Bullet</li>\n</ul>"
	end

	it "syntax highlights code blocks" do
		@post.to_html("<code>\none\ntwo</code>").should == "<code><pre>\n<span class=\"ident\">one</span>\n<span class=\"ident\">two</span></pre></code>"
	end

	it "makes the tags into links to the tag search" do
		@post.tags = "one two"
		@post.linked_tags.should == '<a href="/past/tags/one">one</a> <a href="/past/tags/two">two</a>'
	end

	it "can save itself (primary key is set up)" do
		@post.title = 'hello'
		@post.body = 'world'
		@post.save
		Post.filter(:title => 'hello').first.body.should == 'world'
	end

	it "generates a slug from the title (but saved to db on first pass so that url never changes)" do
		Post.make_slug("RestClient 0.8").should == 'restclient_08'
		Post.make_slug("Rushmate, rush + TextMate").should == 'rushmate_rush_textmate'
		Post.make_slug("Object-Oriented File Manipulation").should == 'objectoriented_file_manipulation'
	end
=end
end
