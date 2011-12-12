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
      addr = "tcp://#{@uri.host}:#{@uri.port}"
      @zctx = ZMQ::Context.new(1)
      @sock = @zctx.socket(ZMQ::DEALER)
      
      if @sock.connect(addr) != 0
        raise ConnectionError.new("Can't connect to #{@uri.to_s}")
      end

      # Authenticate to the vhost.
      join_vhost!(@uri.path, @uri.user, @uri.password)

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

      @sock.close
    end

    def active?
      !!@event_loop and @event_loop.alive? && !@exiting
    end

    def on_error(&block)
      @on_error = block
    end

    def on_event(&block)
      @on_event = block
    end

    def trigger!(event, data={}, directly_to=nil)
      payload = {
        :trigger => {
          :event => event,
          :data => data,
        } 
      }

      if directly_to
        payload[:trigger][:directlyTo] = directly_to
      end

      send!(payload)
    end

    private

    def send!(payload, raise_error=false)
      if (rc = @sock.send_string(marshal(payload))) != 0
        raise SendError.new("Can't send message, error code #{rc}")
      end
    end

    def join_vhost!(vhost, user, secret)
      send!({ 
        :auth => {
          :vhost => vhost,
          :user => user,
          :secret => secret,
        }
      })

      @sock.recv_string(msg = '')
      payload = unmarshal(msg)
      
      if payload["ok"] == true
        return true
      elsif payload.key?("__error")
        raise ClientError.new(payload["__error"])
      else
        raise UnknownError.new("Unknown error while joining the vhost")
      end
    rescue => err
      disconnect
      raise err
    end

    def event_loop
      loop do
        break if @exiting
        @sock.recv_string(msg = '')

        begin
          payload = unmarshal(msg)
          event = payload.keys.first
          data = payload[data]

          @on_event.call(event, data) if @on_event
        rescue => err
          @on_error.call(err, nil) if @on_error
        end
      end
    end

    def unmarshal(msg)
      JSON.parse(msg)
    end

    def marshal(payload)
      payload.to_json
    end
  end # Client
end # WebRocket
