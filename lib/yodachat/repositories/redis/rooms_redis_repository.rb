module YodaChat
  # Internal: Redis driver for the rooms repository.
  class RoomsRedisRepository
    # Public: Creates new chat room.
    #
    # room_name - A string name of the room to be persisted.
    #
    # Returns created room object.
    def self.create(room_name)
      attrs = { :name => room_name }
      $redis.mapped_hmset("room.#{room_name}", attrs)
      Room.new(room_name)
    end

    # Public: Loads specified chat room.
    #
    # room_name - A string name of the room to be loaded.
    #
    # Returns loaded room object. 
    def self.find_by_name(room_name)
      key = "room.#{room_name}"
      return nil unless $redis.exists(key)
      attrs = $redis.hgetall(key)
      Room.new(room_name)
    end

    # Public: Tries to load specified chat room or creates it
    # if not found.
    #
    # room_name - A string name of the room to be loaded or persisted.
    #
    # Returns room object.
    def self.find_by_name_or_create(room_name)
      find_by_name(room_name) or create(room_name)
    end
  end

  class RoomsRepository < RoomsRedisRepository
  end
end
