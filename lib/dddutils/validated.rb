require 'dddutils/errors'

# Internal: This module provides simple validations abstraction
# for the services.
module Validated
  # Internal: This method should contain user validations.
  #
  # Examples:
  #
  #   def validate!
  #     errors << "Name can't be blank" if @name.empty?
  #   end
  #
  def validate!
    raise NotImplementedError.new("#{self.class.name}#validate! not implemented")
  end

  # Internal: Returns list of errors.
  def errors
    @errors ||= Errors.new
  end

  # Internal: Runs validations and returns whether service can
  # proceed or not.
  def valid?
    validate! unless @validated
    @validated == true
    errors.empty?
  end
end
