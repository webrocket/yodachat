require 'ffi-rzmq'
require 'json'
require 'thread'
require 'uri'

module WebRocket
  class ConnectionError < StandardError; end
  class SendError < StandardError; end
  class UnknownError < StandardError; end
  class UnsupportedProtocolError < StandardError; end
  
  class ClientError < StandardError
    attr_reader :status, :code

    def initialize(attrs={})
      @status, @code = attrs.values_at("status", "code")
      super "Error #{@code}: #{@status}"
    end
  end

  class InvalidMessageError < StandardError
    attr_accessor :message
    
    def initialize(data)
      @message = data
      super "Invalid message format"
    end
  end

  class Client
    attr_reader :uri

    def initialize(uri, opts={})
      @uri = URI.parse(uri)
      @timeout = opts[:timeout] || 5

      unless @uri.scheme =~ /^wrs?$/
        raise UnsupportedProtocolError.new("WebRocket supports `wr` and `wrs` protocols only")
      end
    end
    
    def connect
      disconnect

      addr = "tcp://#{@uri.host}:#{@uri.port}"
      @zctx = ZMQ::Context.new(1)
      @sock = @zctx.socket(ZMQ::DEALER)
      
      if @sock.connect(addr) != 0
        raise ConnectionError.new("Can't connect to #{@uri.to_s}")
      end

      # Start listener's event loop in background thread.
      @event_loop = Thread.new { event_loop }
    end

    def disconnect
      if active?
        @exiting = true
        @event_loop.exit if @event_loop.alive?
        @event_loop.join
        @event_loop = nil
      end

      @sock.close if @sock
    end

    def active?
      !!@event_loop and @event_loop.alive? && !@exiting
    end

    def on_exception(&block)
      @on_exception = block
    end

    def on_error(&block)
      @on_error = block
    end

    def on_event(&block)
      @on_event = block
    end

    def broadcast!(channel, event, data={})
      assert_authenticated!
      send!({
        :broadcast => {
          :event => event,
          :data => data,
          :channel => channel
        } 
      })
    end

    def assert_authenticated!
      raise "Not authenticated" unless @authenticated
    end

    private

    def send!(payload, raise_error=false)
      if (rc = @sock.send_string(marshal(payload))) != 0
        raise SendError.new("Can't send message, error code #{rc}")
      end
    end

    def authenticate!(vhost, user, secret)
      @authenticated = false
      
      send!({ 
        :auth => {
          :vhost => vhost,
          :user => user,
          :secret => secret,
        }
      })
    end

    def event_loop
      loop do
        break if @exiting
        @sock.recv_string(payload = '')

        begin
          msg = Message.new(unmarshal(payload))
          break unless dispatch(msg)
        rescue => err
          @on_exception.call(self, err) if @on_exception
        end
      end
    end

    def dispatch(msg)
      case msg.event
      when "__authRequired"
        authenticate!(@uri.path, @uri.user, @uri.password)
      when "__authenticated"
        @authenticated = true
      when "__error"
        if msg.code == 402
          disconnect
          return false
        else
          @on_error.call(self, msg) if @on_error
        end
      else
        @on_event.call(self, msg) if @on_event
      end

      true
    end

    def unmarshal(msg)
      JSON.parse(msg)
    end

    def marshal(payload)
      payload.to_json
    end
  end # Client
  
  class Message < Hash
    attr_reader :event
    
    def initialize(data)
      raise InvalidMessageError.new(data) if data.size != 1
      @event = data.keys.first
      super data[@event]
    end

    def method_missing(meth, *args, &block)
      return self[meth] unless key?(meth)
      super
    end
  end # Message
end # WebRocket
