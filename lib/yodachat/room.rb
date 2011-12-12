require 'ostruct'

module YodaChat
  class RoomNotFoundError < StandardError
    attr_reader :room_id

    def initialize(room_id)
      super "The `#{room_id}` room doesn't exist!"
      @room_id = room_id
    end
  end
  
  class Room < OpenStruct
    def self.room_key(id)
      "room.#{id}"
    end

    def self.find_or_create!(id)
      find(id)
    rescue RoomNotFoundError
      create!(id)
    end
    
    def self.find(id)
      if $redis.exists(key = room_key(id))
        attrs = $redis.hgetall(key)
        new(attrs)
      else
        raise RoomNotFoundError.new(id)
      end
    end

    def self.create!(id)
      new(:id => id, :created_at => Time.now).tap { |room|
        $redis.mapped_hmset(room_key(id), room.to_hash)
      }
    end

    public

    def to_hash
      {
        :id => id,
        :created_at => created_at
      }
    end
  end
end
