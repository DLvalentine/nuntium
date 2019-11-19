# frozen_string_literal: true

require 'open-uri'
require 'colorize'
require 'json'
require 'date'
require_relative '../util.rb'

## Aggregator class for stock symbols, their current value and movement
## TODO: Globalize this -- only US stocks work right now as far as I can tell.
class Stock < Aggregator
  attr_reader :current_symbol

  ## FIXME: carriage return doesn't seem to work with colorize...
  #         might be an encoding problem....
  NO_CHANGE  = '(-)' # .yellow
  POS_CHANGE = '(▲)' # .green
  NEG_CHANGE = '(▼)' # .red
  DAY_IN_SECONDS = 86_400
  CACHE_FILENAME = 'stock_cache.json'

  def initialize(config)
    @symbols = config['symbols']
    @current_symbol = @symbols.first
    @current_symbol_index = 0
    @api = 'W4JK4YBUEQTP6PIZ'

    # local caching
    init_cache
    Util.poll(Stock::DAY_IN_SECONDS) { init_cache }
  end

  ## Get the quote for the current symbol,
  #   move to the next one, and give the output string.
  def read
    ## TODO: need to check cache validity here, too!!
    output_str = @cache[@current_symbol] || quote
    next_symbol
    output_str
  end

  private

  # Hit the API for each symbol at instantiation instead
  # of at runtime, then write to file.
  def init_cache
    @cache = {}

    get_symbol_values = lambda {
      symbol_length = @symbols.length
      symbol_length.times do |_index|
        read
      end
    }

    overwrite_cache_file = lambda {
      File.open(Stock::CACHE_FILENAME, 'w') do |file|
        file.write(@cache.to_json)
      end
    }

    # Attempt to read from file first
    # (over)write file if it doesn't exist, or is 24h+ old.
    if File.exist?(Stock::CACHE_FILENAME)
      yesterday  = (Date.today - 1).to_time.to_i
      tomorrow   = (Date.today + 1).to_time.to_i
      file_ctime = File.ctime(Stock::CACHE_FILENAME).to_date.to_time.to_i

      cache_from_file = JSON.parse(File.read(Stock::CACHE_FILENAME))

      mismatched_keys = cache_from_file.keys.length != @symbols.length # FIXME: Need to check if same length and a symbol changed
      old_cache = !(file_ctime > yesterday && file_ctime < tomorrow)

      if old_cache || mismatched_keys
        get_symbol_values.call
        overwrite_cache_file.call
      else
        @cache = cache_from_file
      end
    else
      get_symbol_values.call
      overwrite_cache_file.call
    end
  end

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
