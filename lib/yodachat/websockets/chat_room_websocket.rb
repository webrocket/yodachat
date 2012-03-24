module YodaChat
  # Public: A Kosmonaut based worker used to handle all user events
  # incoming via the WebRocket.
  class ChatRoomWebsocket
    # Internal: Handles the 'yodaize_and_broadcast' user event.
    # Converts given message into yoda-like sentence and broadcasts
    # it to all subscribers of the specified channel.
    #
    # msg - The Message to be handled.
    #
    def yodaize_and_broadcast(msg)
      chan = msg.delete(:channel).to_s
      room_name = chan.sub(/^presence-room-/, '')
      message, author = *msg.values_at(:message, :author)

      @send_message = SendMessageService.new(room_name, message, author)
      @message, _ = *@send_message.call
      
      msg.broadcast_reply(chan, "messageSent", @message.to_hash)
    end
  end
end
