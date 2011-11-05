require 'rubygems'
require File.join(File.dirname(__FILE__), '../vendor/flightxml2-client-ruby/FlightXML2Driver.rb')
require 'yaml'
require 'json'

CREDENTIALS = YAML.load(File.read('flightxml.yaml'))
AIRLINE_NAMES = JSON.load(File.read('data/airlinecodes.json'))

class Wanderlust
  def initialize(airport, options)
    @airport = airport
    @number = options[:number] || 15
    @api = FlightXML2Soap.new(CREDENTIALS['username'], CREDENTIALS['api_key'])
  end

  def airline_name(ident)
    return nil unless ident && ident.length >= 3
    icao_code = ident[0..2]
    AIRLINE_NAMES[icao_code]
  end

  def load_flights
    results = @api.scheduled(ScheduledRequest.new(@airport, @number, '', 0))
    results.scheduledResult.scheduled
  end

  def pretty_flight(flight)
    (<<-EOF).gsub("\n", ' ')
#{Time.at(flight.filed_departuretime).strftime('%b %d %H:%M')}:
#{airline_name(flight.ident)}
#{flight.aircrafttype}
#{flight.destinationName}
EOF
  end

  def find
    flights = load_flights
    flights.each {|flight| puts pretty_flight(flight)}
  end
end