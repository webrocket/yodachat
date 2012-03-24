module YodaChat
  # Internal: Mock repository for rooms.
  class RoomsMockRepository
    DB = {}

    # Public: Creates new chat room.
    #
    # room_name - A string name of the room to be persisted.
    #
    # Returns created room object.
    def self.create(room_name)
      DB[room_name] = Room.new(room_name)
    end

    # Public: Loads specified chat room.
    #
    # room_name - A string name of the room to be loaded.
    #
    # Returns loaded room object. 
    def self.find_by_name(room_name)
      DB[room_name]
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

  class RoomsRepository < RoomsMockRepository
  end
end
