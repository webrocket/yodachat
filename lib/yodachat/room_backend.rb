require 'yodachat'

module YodaChat
  # Public: A Kosmonaut based worker used to handle all user events
  # incoming via the WebRocket.
  class RoomBackend
    # Internal: Handles the 'yodaize_and_broadcast' user event.
    # Converts given message into yoda-like sentence and broadcasts
    # it to all subscribers of the specified channel.
    #
    # msg - The Message to be handled.
    #
    def yodaize_and_broadcast(msg)
      chan = msg.delete(:channel)
      room = Room.find(chan.sub(/^presence-room-/, ''))
      room.messages.create(msg)
      msg.broadcast_copy(chan, "messageSent")
    end
  end
end
