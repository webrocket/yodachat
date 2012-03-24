module YodaChat
  # Interlan: Redis driver for the messages repository.
  class MessagesRedisRepository
    DB = {}

    # Public: Stores new message in the chat room history.
    #
    # room_name - A string name of the room.
    # message   - A string message to be stored.
    # author    - A string name of the author.
    #
    # Returns created message object.
    def self.create(room_name, message, author)
      Message.new_yodaized(room_name, message, author, Time.now).tap do |msg|
        attrs = {
          :room_name => msg.room_name, 
          :message   => msg.message,
          :author    => msg.author,
          :posted_at => msg.posted_at
        }
        $redis.zadd("room.#{room_name}.messages", msg.posted_at.to_f * 1e6, attrs.to_json)
      end
    end

    # Public: Loads recent history entries for the specified room.
    #
    # room_name - A string name of the room to be loaded.
    # count     - A number of the maximum entries to be loaded.
    #
    # Returns list of history entries. 
    def self.recent_by_room_name(room_name, max = 20)
      entries = $redis.zrange("room.#{room_name}.messages", 0, max - 1).map do |entry|
        attrs = JSON.parse(entry)
        msg = Message.new(*attrs.values_at('room_name', 'message', 'author', 'posted_at'))
        msg.posted_at = Time.at(attrs["posted_at"].to_f).iso8601
        msg
      end

      MessagesHistory.new(entries)
    end
  end

  class MessagesRepository < MessagesRedisRepository
  end
end
