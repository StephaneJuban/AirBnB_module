module AirbnbModule

  # Update the calendar of a given room ID with a price (and note) according to its dates.
  #
  # @session_cookie Required to be cookie from Mechanize session
  # @raise [FalseClass] Error raised when supplied arguments are not valid.
  # @return [TrueClass] or [FalseClass]
  # @overload update_calendar(args = {})
  #   @args session_cookie [Mechanize::CookieJar] The session cookie from a previous login.
  #   @args room_id [Integer] The room ID of the room to update.
  #   @args start_date [String] The start date of the update.
  #   @args end_date [String] The end date of the update.
  #   @args price [Integer] The daily price of the room.
  #   @args note [String] The note to join with the update.
  #   @args availability [String] Must be "available" or "unavailable".
  def update_calendar(args = {})
    require 'uri'
    require 'date'
    require 'net/http'
    require 'rubygems'
    require 'nokogiri'
    require 'open-uri'
    require 'mechanize'
    require 'json'
    
    # Variables declarations
    session_cookie  = args[:session_cookie]   || nil
    room_id         = args[:room_id]          || 5780104
    start_date      = args[:start_date]       || DateTime.now.strftime("%F")
    end_date        = args[:end_date]         || DateTime.now.strftime("%F")
    price           = args[:price]            || 10
    note            = args[:note]             || ""
    availability    = args[:availability]     || "available"
    
    
    ############################################################################
    # Validate the variables
    ############################################################################    
    
    # Need session cookie to continue
    if session_cookie.nil?
      puts "You need to pass session cookie (from Mechanize) to connect to Airbnb."
      return false
    end
    
    # Session cookie must come from Mechanize
    if session_cookie.class != Mechanize::CookieJar
      puts "You need to pass session cookie from Mechanize (Mechanize::CookieJar) only."
      return false
    end
    
    # The price must be > 10 and < 9999
    price = price.truncate
    if price.between?(10, 9999) != true
      puts "Price (#{price}) must be > 10 and < 9999"
      return false
    end
    
    # The availabitily message must be "available" or "unavailable"
    if (availability != "available") and (availability != "unavailable") 
      puts "Availability message (#{availability}) must be \"available\" or \"unavailable\""
      return false
    end
    
    # Check the start date format
    begin
      Date.parse(start_date)
    rescue ArgumentError
      puts "The start date format (#{start_date}) is wrong. Date must be \"YEAR-MONTH-DAY\"."
      return false
    end
    
    # Check the end date format
    begin
      Date.parse(end_date)
    rescue ArgumentError
      puts "The start date format (#{end_date}) is wrong. Date must be \"YEAR-MONTH-DAY\"."
      return false
    end
    
    # End date must be superior or equal of start date
    if end_date < start_date
      puts "End date (#{end_date}) cannot be before start date (#{start_date})."
      return false
    end
    
    # Date must be superior or equal of today
    if start_date < DateTime.now.strftime("%F")
      puts "Start date (#{start_date}) must be superior or equal of today."
      return false
    end
    
    
    # Summarize the update asked...
    puts "Update the Room ID #{room_id}. From #{start_date} to #{end_date} the price will be #{price} and the room will be #{availability}."
    puts "Note for this room : #{note}."
    puts "-----------------------------------"




    ############################################################################
    # Start the updating process for the calendar
    ############################################################################
    
    agent = Mechanize.new
    agent.verify_mode= OpenSSL::SSL::VERIFY_NONE
    
    # Restore cookies from previous session
    agent.cookie_jar = session_cookie
    
    # Go to room's calendar
    page = agent.get "https://www.airbnb.ca/manage-listing/#{room_id}/calendar"
    
    puts "Current page : " + page.title + " | URL : " + page.uri.to_s
    puts "-----------------------------------"
    
    # Get the cookie's variable needed to update the calendar (_csrf_token & _airbed_session_id)
    cookie_csrf_token = ''
    cookie_airbed_session_id = ''
    agent.cookie_jar.each do |value|
      if value.to_s.include? "_csrf_token"
        cookie_csrf_token = value.to_s
      elsif value.to_s.include? "_airbed_session_id"
        cookie_airbed_session_id = value.to_s
      end
    end

    # Create the data to send
    data = {  "availability" => availability,
              "daily_price" => price, 
              "notes" => note
            }.to_json

    # Create the header with the X-CSRF-Token found from previous cookie variable
    headers = { 'X-CSRF-Token' => URI.unescape(cookie_csrf_token.scan(/=(.*)/).join(",")),
                'Content-Type' => 'application/json',
                'Cookie' => "#{cookie_csrf_token}; #{cookie_airbed_session_id}"
              }

    # Parse the calendar page
    noko = Nokogiri::HTML(page.body)
    
    # Get all the parameters for the URL
    param_t = Time.now.to_i
    param_key = ""
    noko.xpath("//meta[@id='_bootstrap-layout-init']/@content").each do |attr|
      param_key = attr.value[/key":"(.*?)"/, 1]
    end
    
    # Construct the URL for the JSON request
    url = "https://www.airbnb.com"
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    # Send the PUT request to update the calendar
    res = http.start { |req|
      req.send_request('PUT', "/api/v2/calendars/#{room_id}/#{start_date}/#{end_date}?_format=host_calendar&t=#{param_t}&key=#{param_key}", data, headers)
    }

    # Return true or false according to the PUT request's response
    if res.kind_of? Net::HTTPSuccess
      return true
    else
      return false
    end

  end
  
end