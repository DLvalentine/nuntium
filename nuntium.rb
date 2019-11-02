# frozen_string_literal: true

require_relative './display/display.rb'
require_relative './aggregator/aggregator.rb'
require_relative 'util.rb'


# TODO : use config, make several aggregators
def main
    aggregator = Aggregator.new('Disk')
    cli = Display.new('Cli')

    Util.listen_for_exit

    cli.display.stream(aggregator)
end

main