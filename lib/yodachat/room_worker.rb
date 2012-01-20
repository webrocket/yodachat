require 'yodachat'

module YodaChat
  class RoomWorker < Kosmonaut::Worker
    def on_message(event, data)
      case event
      when "yodaize_and_broadcast"
        chan = data.delete("channel")
        room = Room.find(chan.sub(/^presence-room-/, ''))
        data = room.transform_and_store_message(data)
        $kosmonaut.broadcast(chan, "messageSent", data)
      else
        raise "Event not supported"
      end
    end

    def on_error(err)
      puts "ERROR: #{err.to_s}"
    end

    def on_exception(err)
      puts "EXCEPTION: #{err.to_s}"
    end
  end
end
