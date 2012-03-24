$LOAD_PATH.unshift(File.expand_path("../../lib"), __FILE__)

require 'redis'

$redis = Redis.new(:db => 2)
$redis.flushdb

require 'rspec'
require 'yodachat'

include YodaChat

RSpec.configure do |conf|
  conf.mock_with :mocha
end
