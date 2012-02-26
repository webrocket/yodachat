require 'ostruct'
require 'active_model'
require 'active_support'
require 'yodachat/room'
require 'json'
require 'time'

module YodaChat
  class Message < OpenStruct
    # Internal: Returns a message class scoped for specified room.
    #
    # room - The room instance to create a scope for.
    #
    def self.for(room)
      klass = Class.new(self)
      klass.instance_variable_set("@room_id", room.id)
      klass
    end

    # Public: Transforms specified message into yoda-like sentence and
    # saves it as a history entry.
    #
    # data - The message's data to be saved.
    #
    # Returns transformed data.
    def self.create(data)
      data.stringify_keys!
      key = Room.key(@room_id, "messages")
      data["message"] = data["message"].to_yoda
      data["posted_at"] = posted_at = Time.now.to_f * 1e6
      $redis.zadd(key, posted_at, data.to_json)
      new(data)
    end

    # Public: Loads specified number of the most recent messages.
    #
    # count - The number of the message to be loaded.
    #
    # Returns list of the messages.
    def self.recent(count=20)
      key = Room.key(@room_id, "messages")
      $redis.zrange(key, 0, count-1).map { |entry|
        data = JSON.parse(entry)
        data["posted_at"] = Time.at(data["posted_at"] / 1e6).iso8601
        new(data)
      }
    end

    public

    # Public: Returns message data as a hash.
    def to_hash
      {
        :author    => author,
        :message   => message,
        :posted_at => posted_at,
      }
    end

    # Public: Returns message serialized to JSON string.
    def to_json
      to_hash.to_json
    end
  end
end
