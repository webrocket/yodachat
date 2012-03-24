require 'dddutils/serializers/hash'

module Serializers
  # Internal: Provides JSON representation for the service.
  module JSON
    include Hash

    # Public: Returns service's results as JSON. 
    def as_json
      r, ok = as_hash
      [r, ok].as_json
    end
  end
end
