module Serializers
  # Internal: Provides hash representation for the service.
  module Hash
    # Public: Returns service results as hash.
    def as_hash
      r, ok = call
      [r.as_hash, ok]
    end
  end
end
