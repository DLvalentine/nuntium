# frozen_string_literal: true

require 'open-uri'
require 'colorize'
require_relative '../util.rb'

## Aggregator class for stock symbols, their current value and movement
class Stock < Aggregator
  attr_reader :current_symbol

  ## FIXME: carriage return doesn't seem to work with colorize...
  #         might be an encoding problem....
  NO_CHANGE  = '-' # .yellow
  POS_CHANGE = '▲' # .green
  NEG_CHANGE = '▼' # .red
  DAY_IN_SECONDS = 86_400

  def initialize(config)
    @symbols = config['symbols']
    @current_symbol = @symbols.first
    @current_symbol_index = 0
    @api = 'W4JK4YBUEQTP6PIZ'

    # "caching"
    # TODO: consider outputting this to a file?
    #       that way if someone start/stops the application, it won't
    #       destroy our API limit that way, either.
    @cache = {}
    Util.poll(Stock::DAY_IN_SECONDS) { @cache = {} }
  end

  ## Get the quote for the current symbol,
  #   move to the next one, and give the output string.
  def read
    ## TODO: pre-emptively get quotes, so scroll doesn't hang up
    #        should work fine since we're caching.
    output_str = @cache[@current_symbol] || quote
    next_symbol
    output_str
  end

  private

  ## Hit the alphavantage API for the given symbol
  #   to get the current value and movement.
  def quote
    endpoint = 'https://www.alphavantage.co/'
    query = "query?function=GLOBAL_QUOTE&symbol=#{@current_symbol}&apikey=#{@api}"

    begin
      # Not using Kernel#Open, Rubocop is dumb
      # rubocop:disable Security/Open
      resp = JSON.parse(open("#{endpoint}#{query}").read)['Global Quote']
      # rubocop:enable Security/Open
    rescue StandardError ## TODO: determine other possible errors...
      @value = 'N/A'
      @movement = Stock::NO_CHANGE
    end

    @value = resp['05. price'].to_i
    change = resp['09. change'].to_i

    @movement = if change.positive?
                  Stock::POS_CHANGE
                elsif change.negative?
                  Stock::NEG_CHANGE
                elsif change.zero?
                  Stock::NO_CHANGE
                else
                  Stock::NO_CHANGE
                end
    @cache[@current_symbol] = "#{@current_symbol} $#{@value} #{@movement}"
  end

  # Move to the next symbol as configured
  def next_symbol
    ### TODO: candidate for pulling out into method on Aggregator
    ### TODO: candidate for optimization
    @current_symbol_index += 1

    if @current_symbol_index >= @symbols.length
      @current_symbol = @symbols.first
      @current_symbol_index = 0
    else
      @current_symbol = @symbols[@current_symbol_index]
    end
  end
end
