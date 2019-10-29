# frozen_string_literal: true

## Parent class for the display/ticking, as it were
# Purpose: to provide common methods to display types, like:
# - Aggregators
# - Current aggregator to read
# - Styling of aggregator
# - ... etc....
class Display
  require_relative 'cli.rb'

  attr_reader :display

  def initialize(type)
    @type = type
    @display = Object.const_get(type).new
  end
end
