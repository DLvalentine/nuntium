# frozen_string_literal: true

require 'json'

## Parent class for all data streams to use in the ticker
class Aggregator
  attr_reader :feed

  def initialize(type, config = nil)
    @type = type
    @feed = Object.const_get(type).new(config || read_config)
  end

  # @returns {Hash} - hash containing the enabled aggregators marked in config.json
  def self.enabled
    JSON.parse(File.read('../config.json'))['aggregators'].select do |k, v|
      {k => v} if v['enabled']
    end
  end

  private

  # @returns {Hash} - hash containing the configuration for this 
  #   instance's type of aggregator, enabled or not.
  def read_config
    JSON.parse(File.read('../config.json'))['aggregators'][@type]
  end
end
