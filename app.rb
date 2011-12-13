require 'bundler/setup'
require 'sinatra'
require 'redis'
require 'digest/sha1'

$redis = Redis.new

set :root, File.dirname(__FILE__)
set :views, File.join(settings.root, "views")
set :public_folder, File.join(settings.root, "public")

$LOAD_PATH.unshift(File.join(settings.root, "lib"))

require 'webrocket/client'

$webrocket = WebRocket::Client.new("wr://yoda:pass@10.1.0.55:9773/yoda") 

$webrocket.on_event { |c, event, data|
  if event == "yodaize_and_send_to_all"
    chan = data.delete("channel")
    data["message"] = data["message"].to_yoda
    c.broadcast!(chan, "message_sent", data)
  else
    puts "#{event}: #{data.inspect}"
  end
}

$webrocket.on_error { |c, err, data|
  puts "ERR: #{err.to_s}"
}

$webrocket.connect

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
