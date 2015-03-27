['sinatra', 'data_mapper', 'dm-sqlite-adapter', 'bcrypt', 'redis'].each {|e| require e}

enable :sessions
set :session_secret, 'super secret'
@@r = Redis.new(:host => '127.0.0.1', :post => 6380)

DataMapper.setup(:default, "sqlite:///#{Dir.pwd}/database/project.db")

class User
	include DataMapper::Resource

	property :id, Serial
	property :username, String
	property :password_hash, String, :length => 255
	property :password_salt, String, :length => 255
	property :created_at, Date

	has n, :posts
end

class Post
	include DataMapper::Resource

	property :id, Serial
	property :title, String
	property :body, Text
	property :url, String
	property :created_at, Date

	belongs_to :user
	has n, :comments
end

class Comment
	include DataMapper::Resource

	property :id, Serial
	property :body, Text
	property :created_at, Date

	belongs_to :post
end

DataMapper.finalize.auto_upgrade!


helpers do
	def is_cached
		tag = "#{request.url}"
		page = @@r.get(tag)
		if page
			return page
		end
	end

	def set_cache(page)
		tag = "#{request.url}"
		@@r.set(tag, page)
		@@r.expire tag, 300
		return page
	end
end


get '/' do
	html = is_cached
	if html
		return html
	end
	@posts = Post.all
	html = erb :index
	set_cache(html)
end

get '/p/:url' do
	html = is_cached
	if html
		return html
	end
	@post = Post.first(:url => params[:url])
	html = erb :post
	set_cache(html)
end

get	'/hardware' do
	erb :hardware
end

get '/project' do
	erb :project
end

get '/about' do
	erb :about
end

get '/contact' do
	erb :contact
end

get '/signup' do
	erb :signup
end

post '/signup' do
	password_salt = BCrypt::Engine.generate_salt
	password_hash = BCrypt::Engine.hash_secret(params[:password], password_salt)

	@u = User.new(:username => params[:username], :password_hash => password_hash, :password_salt => password_salt, :created_at => Time.now)
	if @u.save
		redirect '/login'
	else
		redirect '/signup'
	end
end

get '/login' do
	erb :login
end

post '/login' do
	if @u = User.first(:username => params[:username])
		if @u.password_hash == BCrypt::Engine.hash_secret(params[:password], @u.password_salt)
			session[:username] = params[:username]
			redirect '/admin'
		else
			redirect '/login'
		end
	else
		redirect '/login'
	end
end

get '/logout' do
	session[:username] = nil
	redirect '/'
end

get '/admin' do
	if session[:username].nil?
		redirect '/login'
	else
		erb :admin
	end
end

get '/admin/new_post' do
	if session[:username].nil?
		redirect '/'
	else
		erb :new_post
	end
end

post '/admin/new_post' do
	if session[:username].nil?
		redirect '/'
	else
		@u = User.first(:username => session[:username])
		@post_url = params[:title].downcase.gsub(/[ ]/, '-')
		@p = Post.new(:title => params[:title], :body => params[:body], :url => @post_url, :created_at => Time.now, :user_id => @u.id)
		if @p.save
			redirect '/admin'
		else
			redirect '/admin/new_post'
		end
	end
end
