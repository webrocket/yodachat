module YodaChat
  # Public: Represents single chat room.
  class Room < Struct.new(:name)
    # Public: Returns hash representation of the list.
    def to_hash
      { :name => name }
    end

    # Public: Returns hash representation of the whole object.
    def as_hash
      { :room => to_hash }
    end
  end
end
