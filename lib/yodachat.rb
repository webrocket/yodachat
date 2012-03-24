def require_all(pattern)
  pattern = File.expand_path("../#{pattern}.rb", __FILE__)
  Dir[pattern].each { |file| require file }
end

require 'json'
require 'time'

require_all 'dddutils/**/*'
require_all 'yodachat/utils/*'
require_all 'yodachat/entities/*'
require_all 'yodachat/interactions/*'
require_all 'yodachat/repositories/redis/*'

module YodaChat
end
