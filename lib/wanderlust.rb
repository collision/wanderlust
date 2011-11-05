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
    iterations = ((@number - 1) / 15) + 1
    results = []
    iterations.times {|iteration|
      offset = (iteration-1)*15
      results += @api.scheduled(ScheduledRequest.new(@airport, 15, '', offset)).scheduledResult.scheduled
    }
    results
  end

  def flight_row(flight)
    [
      Time.at(flight.filed_departuretime).strftime('%b %d %H:%M'),
      flight.destinationName,
      airline_name(flight.ident),
      flight.aircrafttype]
  end

  def generate_printstring(flight_rows)
    # Find the appropriate column widths
    num_of_columns = flight_rows.first.length
    column_widths = (0..num_of_columns-1).to_a.map do |index|
      cell_lengths = flight_rows.map {|row| row[index] ? row[index].length : 0}
      cell_lengths.max
    end

    column_widths.map{|width| "%-#{width}s"}.join('  ')
  end

  def print_flights(flights)
    flight_rows = flights.map {|flight| flight_row(flight)}
    printstring = generate_printstring(flight_rows)

    flight_rows.each {|row| puts printstring % row }
  end

  def find
    flights = load_flights
    print_flights(flights)
  end
end