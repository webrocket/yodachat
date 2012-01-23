require 'yodachat'

module YodaChat
  # Public: A Kosmonaut based worker used to handle all user events
  # incoming via the WebRocket.
  class Worker < Kosmonaut::Worker
    # Internal: Handles all incoming user events.
    #
    # event - A name of the event.
    # data  - A data attached to the event.
    #
    def on_message(event, data)
      case event
      when "yodaize_and_broadcast"
        yodaize_and_broadcast(data)
      else
        raise "Event `#{event}` is not supported"
      end
    end

    # Internal: Handles WebRocket's errors.
    #
    # err - The error instance to be handled.
    #
    def on_error(err)
      puts "ERROR: #{err.to_s}"
    end

    # Internal: Handles internal exceptions from within listener.
    #
    # err - The error instance to be handled.
    #
    def on_exception(err)
      puts "EXCEPTION: #{err.to_s}"
    end

    private
    
    # Internal: Handles the 'yodaize_and_broadcast' user event.
    # Converts given message into yoda-like sentence and broadcasts
    # it to all subscribers of the specified channel.
    #
    # data - The message's payload.
    #
    def yodaize_and_broadcast(data)
      chan = data.delete("channel")
      room = Room.find(chan.sub(/^presence-room-/, ''))
      data = room.messages.create(data)
      $kosmonaut.broadcast(chan, "messageSent", data)
      puts "BROADCASTED: `messageSent`: #{data.inspect}"
    end
  end
end
