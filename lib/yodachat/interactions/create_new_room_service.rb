module YodaChat
  # Public: Creates new chat room with specified name.
  #
  # Example:
  #
  #   create_room = CreateNewRoomService.new("hello")
  #   room, ok = *create_room.call
  #   # *snip*
  #
  class CreateNewRoomService
    include Validated
    include Serializers::Hash
    include Serializers::JSON

    # Public: Service's initializer.
    #
    # room_name - A string name of the room to be created.
    #
    def initialize(room_name)
      @room_name = room_name
    end

    # Internal: Checks if given name of the room is not blank.
    def validate!
      errors << "Name can't be blank" if @room_name.empty?
    end
    
    # Public: Executes operation.
    #
    # Returns new room object or list with encountered errors.
    def call
      if valid?
        create_new_room
      else
        [errors, false]
      end
    end

    # Internal: Creates new chat room.
    def create_new_room
      $kosmonaut.open_channel("presence-room-#{@room_name}")
      [RoomsRepository.find_by_name_or_create(@room_name), true]
    rescue Errno::ECONNREFUSED
      errors << "New room created can't be, again later please try"
      [errors, false]
    end
  end
end
