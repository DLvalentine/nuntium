# frozen_string_literal: true

require 'json'

## Parent class for all data streams to use in the ticker
class Aggregator
  require_relative 'disk.rb'
  require_relative 'stock.rb'
  require_relative 'rss.rb'

  attr_reader :feed

  def initialize(type, config = nil)
    @type = type
    begin
      @feed = Object.const_get(type.capitalize).new(config || read_config)
    rescue NameError
      raise ArgumentError, "Aggregator class \"#{@type}\" does not exist."
    end
  end

  ## TODO: actually this will be useful, I just need to implement it correctly.
  ## TODO: Only here to serve as an implementation reminder. Remove for prod.
  # rubocop:disable all
  def method_missing(method_called)
    raise StandardError, 
      "Method \"#{method_called}\" does not exist for Aggregator class: #{@type}"
  end
  # rubocop:enable all

  private

  # @returns {Hash} - hash containing the configuration for this
  #   instance's type of aggregator.
  def read_config
    JSON.parse(File.read('./config.json'))['aggregators'][@type]
  end
end
