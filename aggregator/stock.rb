# frozen_string_literal: true

require 'open-uri'
require 'json'
require 'date'
require_relative '../util.rb'

## Aggregator class for stock symbols, their current value and movement
# NOTE: restricted by alphavantage's TPS/rules -- see: https://www.alphavantage.co/support/#api-key
# If you're having trouble with the stock feature, consider getting your own damn API key ;)
class Stock < Aggregator
  attr_reader :current_symbol

  NO_CHANGE      = '(-)'
  POS_CHANGE     = '(▲)'
  NEG_CHANGE     = '(▼)'
  NO_VALUE       = '-'
  DAY_IN_SECONDS = 86_400
  CACHE_FILENAME = 'stock_cache.json'
  STOCK_TPS      = 65 # 5 calls per 60 secs permitted, 500 calls per day

  def initialize(config)
    @symbols = config['symbols']
    @current_symbol = @symbols.first
    @current_symbol_index = 0
    @api = 'W4JK4YBUEQTP6PIZ' # I know, sue me

    # local caching
    init_cache
    Util.poll(Stock::DAY_IN_SECONDS) { init_cache }
  end

  ## Get the quote for the current symbol,
  #   move to the next one, and give the output string.
  def read
    output_str = @cache[@current_symbol] || quote
    next_symbol
    output_str
  end

  private

  # Hit the API for each symbol at instantiation instead
  # of at runtime, then write to file.
  # TODO: Pull out caching piece into utils...? Maybe?
  # TODO: LOADING TEXT!!!
  def init_cache
    @cache = {}

    get_symbol_values = lambda {
      symbol_length = @symbols.length
      symbol_length.times do |index|
        # API limits -- if you are tracking more than 5 symbols, I'll have to add a delay
        if symbol_length > 5 && index > 4 # TODO: move to handling this in batches of 5.
          Util.wait(STOCK_TPS) { quote }
        else
          read
        end
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
      file_ctime = File.mtime(Stock::CACHE_FILENAME).to_date.to_time.to_i

      cache_from_file = JSON.parse(File.read(Stock::CACHE_FILENAME))

      mismatched_keys = (cache_from_file.keys.length != @symbols.length) ||
                        cache_from_file.keys != @symbols
      old_cache = !(file_ctime > yesterday && file_ctime < tomorrow)

      if old_cache || mismatched_keys
        File.delete(Stock::CACHE_FILENAME)
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
  # Global stocks work, but the format is... different.
  def quote
    endpoint = 'https://www.alphavantage.co/'
    query = "query?function=GLOBAL_QUOTE&symbol=#{@current_symbol}&apikey=#{@api}"

    # Not using Kernel#Open, Rubocop is dumb
    # rubocop:disable Security/Open
    resp = JSON.parse(open("#{endpoint}#{query}").read)['Global Quote']
    # rubocop:enable Security/Open

    if resp.nil?
      @value = Stock::NO_VALUE
      @movement = Stock::NO_CHANGE
    else
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
    end

    old_value = @cache[@current_symbol]
    @cache[@current_symbol] = "#{@current_symbol} $#{@value} #{@movement}"

    return unless @cache[@current_symbol] != old_value

    # TODO: DRY this up, make sure it isn't being called too much (see init_cache)
    # TODO: simple file operations like this are a good candidate for optimization/moving
    File.open(Stock::CACHE_FILENAME, 'w') do |file|
      file.write(@cache.to_json)
    end
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
