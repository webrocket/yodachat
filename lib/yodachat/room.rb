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
    def self.room_key(id, suffix=nil)
      "room.#{id}#{suffix ? ".#{suffix}" : ""}"
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
    
    def transform_and_store_message(data)
      key = self.class.room_key(id, "history")
      data["message"] = data["message"].to_yoda
      data["posted_at"] = posted_at = Time.now.to_i
      $redis.zadd(key, posted_at, data.to_json)
      data
    end
    
    def recent_messages(count=20)
      key = self.class.room_key(id, "history")
      $redis.zrange(key, 0, count).map { |entry|
        data = JSON.parse(entry)
        data["posted_at"] = Time.at(data["posted_at"]).iso8601
        data
      }
    end

    def to_hash
      {
        :id => id,
        :created_at => created_at
      }
    end
  end
end
