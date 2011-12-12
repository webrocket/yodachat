$LOAD_PATH.unshift(File.expand_path("../../lib"), __FILE__)

require 'redis'

$redis = Redis.new(:db => 2)

require 'rspec'
require 'yodachat'

RSpec.configure do |conf|
  conf.mock_with :mocha
end
