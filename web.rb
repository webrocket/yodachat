require File.expand_path("../init", __FILE__)
require 'sinatra'
require 'rack-flash'
require 'digest/sha1'
require 'uri'

set :root, $ROOT_PATH
set :views, File.join($ROOT_PATH, "views")
set :public_folder, File.join($ROOT_PATH, "public")
set :sessions, true

use Rack::Flash
include YodaChat

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end

  def redirect_with_errors(where, errors)
    flash[:error] = @errors.to_s
    redirect "/"
  end
end

get '/' do
  erb :index
end

get '/how' do
  erb :how
end

get '/webrocket' do
  erb :webrocket
end

post '/new' do
  room_name = Digest::SHA1.hexdigest(Time.now.to_s + (rand(1000000) + 1000).to_s)
  create_room = CreateNewRoomService.new(room_name)
  @room, ok = *create_room.call
  
  if ok
    $kosmonaut.open_channel("presence-room-#{@room.name}")
    flash[:notice] = "The room created has been!"
    redirect "/room/#{room_name}"
  else
    redirect_with_errors("/", @room)
  end
end

get '/room/:id' do |room_name|
  join_room = JoinRoomService.new(room_name)
  @room, ok = *join_room.call
  
  if ok
    erb :room
  else
    status 404
  end
end

get '/room/:id/history.json' do |room_name|
  load_history = LoadRoomHistoryService.new(room_name)
  @history, ok = *load_history.as_hash

  if ok
    content_type "application/json"
    @history.to_json
  else
    status 404
  end
end

get '/webrocket/auth.json' do
  @channel, @uid = params.values_at(:channel, :uid)
  @single_access_token = $kosmonaut.request_single_access_token(@uid, @channel)

  content_type "application/json"
  { :token => @single_access_token }.to_json
end

not_found do
  File.read(File.join(settings.public_folder, "404.html"))
end
