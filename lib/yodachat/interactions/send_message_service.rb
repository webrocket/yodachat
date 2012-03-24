module YodaChat
  # Public: Stores specified message to the chat room history.
  #
  # Example:
  #
  #   send_message = SendMessageService.new("room", "Hello World!", "Luke Skywalker")
  #   message, ok = *send_message.call
  #   # *snip*
  #
  class SendMessageService
    include Validated
    include Serializers::Hash
    include Serializers::JSON

    # Public: Service's initializer.
    #
    # room_name - A string name of the room.
    # message   - A string message to be sent.
    # author    - A string author name.
    #
    def initialize(room_name, message, author)
      @room = RoomsRepository.find_by_name(room_name)
      @message, @author = message, author
    end

    # Internal: Checks if room exists and given message is not empty.
    def validate!
      errors << "Room doesn't exist" unless @room
      errors << "Message can't be blank" if @message.empty?
    end

    # Public: Executes operation. 
    #
    # Returns saved message information or list with encountered
    # errors.
    def call
      if valid?
        [store_message, true]
      else
        [errors, false]
      end
    end

    # Internal: Saves message.
    def store_message
      MessagesRepository.create(@room.name, @message, @author)
    end
  end
end
