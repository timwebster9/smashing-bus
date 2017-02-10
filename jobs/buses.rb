require 'httparty'
require 'json'
require 'time'

class BusArrival
  def initialize(currentTime, busNo, arrivalTime)
    @currentTime = currentTime
    @busNo=busNo
    @arrivalTime=arrivalTime
  end

  def busNo
    @busNo
  end

  def arrivalTime
    @arrivalTime
  end

  def eta
    ((@arrivalTime - @currentTime) / 60).round.to_s
  end

  def to_json(*a)
        {
          'busNo' => @busNo,
          'eta' => self.eta
        }.to_json(*a)
  end

end

SCHEDULER.every '10s', :first_in => 0 do

	response = HTTParty.get("https://api.tfl.gov.uk/StopPoint/490010284W/Arrivals?mode=bus")
  parsed = response.parsed_response

  busArrivals = []
  currentTime = Time.now

  parsed.each do |bus|
    busNo = bus["lineId"]
    expectedArrival = bus["expectedArrival"]
    eaDate = Time.parse(expectedArrival)

    busArrival=BusArrival.new(currentTime, busNo, eaDate)
    busArrivals.push(busArrival)
  end

  busArrivals.sort_by! {|bus| bus.arrivalTime}
  busesJson = JSON.parse(busArrivals.to_json)
  puts busesJson

  send_event('buses', items: busesJson)

  #busArrivals.each do |buses|
  #  print buses.busNo
  #  print " "
  #  print buses.arrivalTime
  #  print " "
  #  puts buses.eta
  #end

end
