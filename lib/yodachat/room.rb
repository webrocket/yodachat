require 'ostruct'
require 'active_model'

module YodaChat
  class Room < OpenStruct
    class NotFoundError < StandardError
      def initialize(room_id)
        super "Room #{room_id} not found!"
      end
    end

    include ActiveModel::Validations
    
    validates :id, :format => /^[\w\d\_\-\s]{,32}$/

    validates_each :id do |room, _, value| 
      begin
        Room.find(value)
        room.errors.add(:id, "already exists")
      rescue NotFoundError
      end
    end

    def self.key(id, suffix=nil)
      "room.#{id}#{suffix ? ".#{suffix}" : ""}"
    end

    def self.find_or_create(id)
      find(id)
    rescue NotFoundError
      create(id)
    end
    
    def self.find(id)
      if $redis.exists(key = key(id))
        #$kosmonaut.open_channel("presence-room-#{id}") if $kosmonaut
        attrs = $redis.hgetall(key)
        new(attrs)
      else
        raise NotFoundError.new(id)
      end
    end

    def self.create(id)
      room = new(:id => id, :created_at => Time.now)
      return false unless room.valid?
      $redis.mapped_hmset(key(id), room.to_hash)
      $kosmonaut.open_channel("presence-room-#{id}") if $kosmonaut
      room
    end

    public
    
    def transform_and_store_message(data)
      key = self.class.key(id, "history")
      data["message"] = data["message"].to_yoda
      data["posted_at"] = posted_at = Time.now.to_i
      $redis.zadd(key, posted_at, data.to_json)
      data
    end
    
    def recent_messages(count=20)
      key = self.class.key(id, "history")
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
