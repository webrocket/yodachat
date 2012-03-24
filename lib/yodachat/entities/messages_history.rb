module YodaChat
  # Public: Chat room history entries list.
  class MessagesHistory < Array
    # Public: Returns hash representation of the list.
    def to_hash
      map(&:to_hash)
    end
    
    # Public: Returns hash representation of the whole object.
    def as_hash
      { :history => to_hash }
    end
  end
end
