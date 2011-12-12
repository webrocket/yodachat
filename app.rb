require 'bundler/setup'
require 'sinatra'
require 'redis'
require 'digest/sha1'

$redis = Redis.new
#$webrocket = WebRocket::Client.new("wr://yoda:secret@127.0.0.1:9773/yoda") 

set :root, File.dirname(__FILE__)
set :views, File.join(settings.root, "views")
set :public_folder, File.join(settings.root, "public")

$LOAD_PATH.unshift(File.join(settings.root, "lib"))

require 'yodachat'
include YodaChat

get '/' do
  erb :index
end

post '/new' do
  room_id = Digest::SHA1.hexdigest(Time.now.to_s + (rand(1000000) + 1000).to_s)
  redirect "/#{room_id}"
end

get '/:id' do
  @room = Room.find_or_create!(params[:id])
  erb :room
end
