require 'bundler/setup'
require 'ffi-rzmq'
require 'json'

zctx = ZMQ::Context.new(1)
sock = zctx.socket(ZMQ::ROUTER)
sock.bind("tcp://127.0.0.1:9776")

loop do
  sock.recv_strings(lines = [])
  sender, msg = *lines
  puts msg

  payload = JSON.parse(msg)
  event = payload.keys.first
  data = payload[event]
  
  puts payload.inspect

  case event
  when "auth"
    if data["user"] == "user" && data["secret"] == "pass" && data["vhost"] == "/vhost"
      sock.send_strings([sender, {"ok" => true}.to_json])
    else
      sock.send_strings([sender, {"__error" => {"code" => 401, "status" => "Unauthorized"}}.to_json])
    end
  when "trigger"
    
  end
end

sock.close
zctx.terminate
