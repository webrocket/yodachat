require File.expand_path("../spec_helper", __FILE__)
require 'yodachat/websockets/chat_room_websocket'
require 'securerandom'

describe YodaChat::ChatRoomWebsocket do
  let :message do
    {
      :channel => "presence-room-hello", 
      :message => "The force is strong in you!", 
      :author  => "Yoda"
    }
  end

  it "broadcast yodaized message to users" do
    new_msg = message.dup
    new_msg[:message] = new_msg[:message].to_yoda
    mock_service = mock(:call => [new_msg, true])
    SendMessageService.expects(:new).with("hello", "The force is strong in you!", "Yoda").returns(mock_service)
    message.expects(:broadcast_reply).with("presence-room-hello", "messageSent", new_msg)
    subject.yodaize_and_broadcast(message)
  end
end
