# frozen_string_literal: true

## Parent class for all data streams to use in the ticker
# Purpose: To provide aggregators with common methods/state - such as:
# - current file/feed/etc.
# - getter for source of file/feed/etc.
class Aggregator
  attr_reader :source, :feed

  def initialize(type)
    @feed = Object.const_get(type)
    @source = 'some source' # @feed.source
  end
end
