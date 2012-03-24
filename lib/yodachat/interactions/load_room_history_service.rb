module YodaChat
  # Public: Loads recent history entries for the specified 
  # chat room.
  #
  # Example:
  #
  #   load_history = LoadRoomHistoryService.new("hello")
  #   history_entries, ok = *load_history.call
  #   # *snip*
  #   
  class LoadRoomHistoryService
    include Validated
    include Serializers::Hash
    include Serializers::JSON

    # Public: Service's initializer.
    #
    # room_name - A string name of the room to be loaded.
    #
    def initialize(room_name)
      @room = RoomsRepository.find_by_name(room_name)
    end

    # Internal: Checks if specified room exists.
    def validate!
      errors << "Room doesn't exist" unless @room
    end

    # Public: Executes operation.
    #
    # Returns list of recent history entries or list with
    # encountered errors.
    def call
      if valid?
        [load_history, true]
      else
        [errors, false]
      end
    end

    # Internal: Loads recent history entries.
    #
    # Returns list of messages.
    def load_history
      MessagesRepository.recent_by_room_name(@room.name)
    end
  end
end
