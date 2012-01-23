require 'ostruct'
require 'active_model'
require 'yodachat/message'

module YodaChat
  # Public: Representation of the room record. 
  #
  # Examples
  # 
  #     room = Room.create("hello")
  #     room.messages.create(
  #       :message => "The force is strong in you!",
  #       :author  => "Master Yoda"
  #     )
  #
  class Room < OpenStruct
    # Public: Error thrown when given romm couldn't be found.
    class NotFoundError < StandardError
      def initialize(room_id)
        super "Room #{room_id} not found!"
      end
    end

    include ActiveModel::Validations
    
    # Room id can contain only letters, digits, underscores
    # and dashes. Can't be longer than 32 characters.
    validates :id, :format => /^[\w\d\_\-]{,32}$/

    # Validating uniqueness of the room's name.
    validates_each :id do |room, _, value| 
      begin
        Room.find(value)
        room.errors.add(:id, "already exists")
      rescue NotFoundError
      end
    end
    
    # Internal: Composes redis key for given room id.
    #
    # id     - The room id to be packed.
    # suffix - A key's suffix.
    #
    # Examples
    #
    #     Room.key("hello", "world")
    #     # => "room.hello.world"
    #
    # Returns composed room's key.
    def self.key(id, suffix=nil)
      "room.#{id}#{suffix ? ".#{suffix}" : ""}"
    end

    # Public: Finds room with the specified ID. If there's no such one
    # in the database then it creates a new record for it.
    #
    # id - An ID of the room to be found or created.
    #
    # Returns a room instance.
    def self.find_or_create(id)
      find(id)
    rescue NotFoundError
      create(id)
    end
    
    # Public: Finds room with the specified ID. If there's no such one
    # in the database then a Kosmonaut::Room::NotFoundError will be thrown.
    #
    # id - An ID of the room to be found.
    #
    # Returns a room instance.
    def self.find(id)
      if $redis.exists(key = key(id))
        attrs = $redis.hgetall(key)
        new(attrs)
      else
        raise NotFoundError.new(id)
      end
    end

    # Public: Creates new room with the specified ID and creates the
    # WebRocket's channel for it as well. 
    #
    # id - An ID of the room to be created.
    #
    # Returns created room instance.
    def self.create(id)
      room = new(:id => id)
      room.save
      room
    end

    public

    # Public: Saves the room's information and returns whether attributes
    # are alid or not.
    def save
      return false unless valid?
      self.created_at = Time.now
      $redis.mapped_hmset(self.class.key(id), to_hash)
      $kosmonaut.open_channel("presence-room-#{id}") if $kosmonaut
      true
    end

    # Public: Returns a messages scope.
    #
    # Examples
    #
    #     room.messages.create(:message => "Hello Space!")
    #     room.messages.recent.each { |msg| ... }
    #     
    def messages
      @messages ||= Message.for(self)
    end
    
    # Public: Returns room information as a hash.
    def to_hash
      {
        :id => id,
        :created_at => created_at
      }
    end
  end
end
