module ROM
  # Raised when the returned tuples are unexpectedly empty
  NoTuplesError = Class.new(RuntimeError)

  # Raised when the returned tuples are unexpectedly too many
  ManyTuplesError = Class.new(RuntimeError)

  # Represent an undefined argument
  Undefined = Class.new.freeze

  # An empty frozen Hash useful for parameter default values
  EMPTY_HASH = {}.freeze

  # An empty frozen Array useful for parameter default values
  EMPTY_ARRAY = [].freeze
end
