# frozen_string_literal: true

require_relative '../util.rb'

require 'htmlentities'
require 'launchy'
require 'open-uri'
require 'simple-rss'
require 'httparty'

## Aggregator class for RSS Feeds, their content, etc.
class Rss < Aggregator
  attr_reader :current_feed

  RSS_REFRESH_TIME_SECONDS   = 7_200
  CACHE_FILENAME             = 'rss_cache.json'
  NO_VALUE                   = 'N/A'
  WCID                       = '3_1wh9mo5a00lc08c4000g4k88sk8gw4w0o8gcs0w0cgw0c8o0cg';
  WSCT                       = '1altysnzjt40ggs4s48w408o0o4wgk4k0gs0w84ocgwk8cocs0';
  WALLABAG_HOST              = 'http://localhost'
  WALLABAG_BOOKMARK_ENDPOINT = "#{WALLABAG_HOST}/api/entries"
  WALLABAG_AUTH_ENDPOINT     = "#{WALLABAG_HOST}/oauth/v2/token"
  

  def initialize(config)
    @feeds = config['feeds']
    append_ifeeds(config['i_feeds'])

    @current_feed = @feeds.first
    @current_feed_index = 0
    @current_feed_link = ''

    # local caching
    init_cache
    Util.poll(Rss::RSS_REFRESH_TIME_SECONDS) do
      init_cache
      Util.clear_term # TODO: did this work? When the feed refreshes, we get some weird line clearing stuff... Started happening after RSSHub integ
    end
    Keyboard.add_shortcut('o') { Launchy.open(@current_feed_link) }
    Keyboard.add_shortcut(' ') { Launchy.open(@current_feed_link) }
  end

  ## Get the rss info for the current feed,
  #  move on to the next one, and  give the output string.
  def read
    begin
      title              = @current_feed.keys.first
      ## todo: shift probaly not the right thing... or if it is, need to rewrite cache...
      content            = @cache[@current_feed.keys.first] || fetch_feed
      @current_feed_link = content[0]&.dig('link')
      decoded_content    = HTMLEntities.new.decode(content&.shift&.dig('title'))
      @cache[@current_feed.keys.first] = nil if content.empty?
      next_feed
      "<#{title}>: #{decoded_content || Rss::NO_VALUE}"
    rescue => e
      # Error while parsing, something weird during feed fetch, not read, probably
      # TODO: Build a better handler for this, skip feed? drop feed? For now, don't recover, throw error.
      puts e
      exit!
    end
  end

  private

  # Ping the internal RSSHub instance - if it is online, append those feeds.
  def append_ifeeds(i_feeds)
    @feeds.concat(i_feeds) if Util.local_rsshub_online?
  end

  # Hit the feed for each feed URI at instantiation instead of
  # at runtime, then write to file.
  def init_cache
    @cache = {}

    get_feed_values = lambda {
      feed_length = @feeds.length
      feed_length.times do |_index|
        read
      end
    }

    overwrite_cache_file = lambda {
      File.open(Rss::CACHE_FILENAME, 'w') do |file|
        file.write(@cache.to_json)
      end
    }

    # Attempt to read from file first
    # (over)write file if it doesn't exist, or is 1h+ old.
    if File.exist?(Rss::CACHE_FILENAME)
      last_refresh = (Time.now - Rss::RSS_REFRESH_TIME_SECONDS).to_i
      next_refresh = (Time.now + Rss::RSS_REFRESH_TIME_SECONDS).to_i
      file_ctime   = File.mtime(Rss::CACHE_FILENAME).to_time.to_i

      cache_from_file = JSON.parse(File.read(Rss::CACHE_FILENAME))

      mismatched_keys = (cache_from_file.length != @feeds.length ||
                        cache_from_file.keys != @feeds.map(&:keys).flatten)
      old_cache = !(file_ctime > last_refresh && file_ctime < next_refresh)

      if old_cache || mismatched_keys
        File.delete(Rss::CACHE_FILENAME)
        get_feed_values.call
        overwrite_cache_file.call
      else
        @cache = cache_from_file
      end
    else
      get_feed_values.call
      overwrite_cache_file.call
    end
  end

  ## Use simple-rss to get the latest feed data for
  #  the current feed URI/source
  def fetch_feed
    endpoint = @current_feed.values.first

    begin
      document = SimpleRSS.parse(URI.open(endpoint))
    rescue => e
      puts "Error: <#{e}> while trying to call <#{@current_feed_link}>"
      # effectively skip document
      document = { title: Rss::NO_VALUE, items: {} }
    end

    # Ensuring string access instead of symbol access.
    # I know there's probably a better way to do this...
    # but I can't remember if with_indifferent_access is
    # a rails thing...
    @cache[@current_feed.keys.first] = JSON.parse(document.items.to_json)
  end

  ### TODO: probably candidate for pulling out into method on Aggregator
  def next_feed
    @current_feed_index += 1

    if @current_feed_index >= @feeds.length
      @current_feed = @feeds.first
      @current_feed_index = 0
    else
      @current_feed = @feeds[@current_feed_index]
    end
  end
end
