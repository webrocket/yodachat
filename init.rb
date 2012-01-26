$ROOT_PATH = File.dirname(__FILE__)
$LOAD_PATH.unshift(File.join($ROOT_PATH, "lib"))

# This URL shall be used by the frontend WebRocket client.
$WEBSOCKET_URL = ENV['KOSMONAUT_WEBSOCKET_URL']

require 'bundler/setup'
require 'redis'
require 'kosmonaut'
require 'yodachat/worker'

# Initialize redis client and connect it to specified URL.
$redis = Redis.connect(:url => ENV["REDIS_URL"])

# Initialize Kosmonaut REQ client and connect it to specified URL.
$kosmonaut = Kosmonaut::Client.new(ENV["KOSMONAUT_BACKEND_URL"])
