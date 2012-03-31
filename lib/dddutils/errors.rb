# Internal: Dummy errors representation.
class Errors < Array
  # Public: Returns hash representation of the errors.
  def as_hash
    { :errors => self }
  end

  # Public: String representation of the errors.
  def to_s
    self.join(', ')
  end
end
