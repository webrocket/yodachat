module YodaChat
  # Internal: Mock repository for chat messages.
  class MessagesMockRepository
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
        DB[room_name] ||= []
        DB[room_name] << msg
      end
    end
    
    # Public: Loads recent history entries for the specified room.
    #
    # room_name - A string name of the room to be loaded.
    # count     - A number of the maximum entries to be loaded.
    #
    # Returns list of history entries. 
    def self.recent_by_room_name(room_name, count = 20)
      entries = DB[room_name] || []
      MessagesHistory.new(entries)
    end
  end

  class MessagesRepository < MessagesMockRepository
  end
end
