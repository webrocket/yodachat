module YodaChat
  # Public: Represents single chat room message.
  #
  # Example:
  #
  #   msg = Message.new_yodaized("room", "The force is strong in you!", "Yoda")
  #   msg.message # => "Strong in you, the force is!"
  #
  class Message < Struct.new(:room_name, :message, :author, :posted_at)
    # Public: Creates new message with yodaized content. This method
    # should be used over +new+.
    #
    # room_name - A string name of the parent room.
    # message   - A string message text.
    # author    - A string name of the autor.
    # posted_at - A Time when message has been created.
    #
    # Returns new message.
    def self.new_yodaized(room_name, message, author, posted_at = nil)
      message = message.to_yoda
      posted_at ||= Time.now
      new(room_name, message, author, posted_at)
    end

    # Public: Returns parent room object.
    def room
      RoomsRepository.find_by_name(room_name)
    end

    # Public: Returns hash representation of the list.
    def to_hash
      { 
        :room      => room_name,
        :message   => message,
        :author    => author,
        :posted_at => posted_at.iso8601
      }
    end

    # Public: Returns hash representation of the whole object.
    def as_hash
      { :message => to_hash }
    end
  end
end
