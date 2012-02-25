require File.expand_path("../init", __FILE__)
require 'yodachat/room_backend'

# Uncomment following line if you want to run Kosmonaut worker in
# debug mode (Prepare for nice flood of the heartbeat messages :P).
#Kosmonaut.debug = true

# Configure and run Kosmonaut application.
Kosmonaut::Application.new ENV['KOSMONAUT_BACKEND_URL'] do
  # Register backend handlers.
  use YodaChat::RoomBackend, :as => "chat"
  
  # Set logging options...
  logger.level = Logger::DEBUG
  logger.progname = "Kosmonaut"

  # And run the application.
  run
end
