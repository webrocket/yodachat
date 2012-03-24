module YodaChat
  # Public: Performs operation of joining the chat room. Loads
  # specified chat room information.
  #
  # Example:
  #
  #   join_room = JoinRoomService.new("hello")
  #   room, ok = *join_room.call
  #   # *snip*
  #
  class JoinRoomService
    include Validated
    include Serializers::Hash
    include Serializers::JSON

    # Public: Service's initializer.
    #
    # room_name - A string name of the room to join.
    #
    def initialize(room_name)
      @room = RoomsRepository.find_by_name(room_name)
    end

    # Internal: Checks if the room exists.
    def validate!
      errors << "Room doesn't exist" unless @room
    end

    # Public: Executes operation.
    #
    # Returns room information or list with encountered errors.
    def call
      if valid?
        [@room, true]
      else
        [errors, false]
      end
    end
  end
end
