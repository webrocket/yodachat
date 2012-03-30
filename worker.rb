require File.expand_path("../init", __FILE__)
require 'yodachat/websockets/chat_room_websocket'

# Configure and run Kosmonaut application.
Kosmonaut::Application.new ENV['KOSMONAUT_BACKEND_URL'] do
  # Register backend handlers.
  use YodaChat::ChatRoomWebsocket, :as => "chat"
  
  # Set logging options...
  logger.level = Logger::DEBUG
  logger.progname = "Kosmonaut"

  # And run the application.
  run
end
