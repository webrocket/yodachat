require File.expand_path("../init", __FILE__)

# Uncomment following line if you want to run Kosmonaut worker in
# debug mode (Prepare for nice flood of the heartbeat messages :P).
#Kosmonaut.debug = true

# Create new worker connected to specified backend URL.
$worker = YodaChat::Worker.new(ENV["KOSMONAUT_BACKEND_URL"])

# Start listener, will block until you terminate the process.
$worker.listen
