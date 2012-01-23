$ROOT_PATH = File.dirname(__FILE__)
$LOAD_PATH.unshift(File.join($ROOT_PATH, "lib"))
$WEBSOCKET_URL = ENV['KOSMONAUT_WEBSOCKET_URL']

require 'bundler/setup'
require 'redis'
require 'kosmonaut'
require 'yodachat/worker'

$redis     = Redis.new(:url => ENV["REDIS_URL"])
$kosmonaut = Kosmonaut::Client.new(ENV["KOSMONAUT_BACKEND_URL"])
