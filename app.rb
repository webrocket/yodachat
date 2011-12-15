require 'bundler/setup'
require 'sinatra'
require 'rack-flash'
require 'redis'
require 'digest/sha1'
require 'uri'

$redis = Redis.new

set :root, File.dirname(__FILE__)
set :views, File.join(settings.root, "views")
set :public_folder, File.join(settings.root, "public")
enable :sessions

use Rack::Flash

$LOAD_PATH.unshift(File.join(settings.root, "lib"))

require 'webrocket/client'
require 'yodachat'
include YodaChat

$webrocket = WebRocket::Client.new("wr://yoda:pass@10.1.0.55:9773/yoda") 

$webrocket.on_event { |c, event, data|
  if event == "yodaize_and_send_to_all"
    chan = data.delete("channel")
    room = Room.find(chan)
    data = room.transform_and_store_message(data)
    c.broadcast!(chan, "message_sent", data)
  else
    puts "#{event}: #{data.inspect}"
  end
}

$webrocket.on_error { |c, err, data|
  puts "ERR: #{err.to_s}"
}

$webrocket.connect  

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

get '/' do
  erb :index
end

# TODO: move validations to the model...
post '/new' do
  room_id = if params["chat_name"].to_s.empty?
    Digest::SHA1.hexdigest(Time.now.to_s + (rand(1000000) + 1000).to_s)
  else
    URI.escape(params["chat_name"]);
  end
  
  begin
    Room.find(room_id)
    flash[:error] = "Room with such name already exists"
  rescue RoomNotFoundError => err
    # room doesn't exist, so we can create one...
  end
  
  unless room_id =~ /^[\w\d\_\-\s]{,32}$/i
    flash[:error] = "Channel name contains invalid characters or is too long"
  end
  
  redirect flash[:error] ? "/" : "/room/#{room_id}"
end

get '/room/:id' do
  @room = Room.find_or_create!(params[:id])
  @entries = @room.recent_messages
  erb :room
end

get '/room/:id/history.json' do
  content_type "application/json"
  @room = Room.find(params[:id])
  @room.recent_messages.to_json
end
