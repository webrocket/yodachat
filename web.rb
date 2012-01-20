require File.expand_path("../init", __FILE__)
require 'sinatra'
require 'rack-flash'
require 'digest/sha1'
require 'uri'

set :root, $ROOT_PATH
set :views, File.join($ROOT_PATH, "views")
set :public_folder, File.join($ROOT_PATH, "public")
enable :sessions
use Rack::Flash
include YodaChat

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

get '/' do
  erb :index
end

post '/new' do
  room_id = if params["chat_name"].to_s.empty?
    Digest::SHA1.hexdigest(Time.now.to_s + (rand(1000000) + 1000).to_s)
  else
    URI.escape(params["chat_name"]);
  end
  if @room = Room.create(room_id)
    flash[:notice] = "The room created has been!"
    redirect "/room/#{room_id}"
  else
    erb :index
  end
end

get '/room/:id' do
  @room = Room.find_or_create(params[:id])
  @entries = @room.recent_messages
  erb :room
end

get '/room/:id/history.json' do
  content_type "application/json"
  @room = Room.find(params[:id])
  @room.recent_messages.to_json
end
