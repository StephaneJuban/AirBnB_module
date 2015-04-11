require './airbnb_module.rb'
require 'mechanize'
include AirbnbModule


room_id = 0000000
email = "my_email@yolo.com"
password = "123456"
############################################################################
# For test purpose, we simulate the login process (to get cookies)
############################################################################

login_url = 'https://www.airbnb.ca/login_modal'
agent = Mechanize.new
#agent.set_proxy('210.101.131.231', 8080)
agent.verify_mode= OpenSSL::SSL::VERIFY_NONE

# Load the login page to retrieve cookie and authenticity token
page = agent.get(login_url)

# Retrieve the authenticity token with Nokogiri
noko = Nokogiri::HTML(page.body)
token = noko.at_xpath("//input[@name='authenticity_token']")['value']

# Get the form from this page using its class parameter
form = page.form_with(:class => 'signin-form login-form')

# Fill all the fields (even hidden ones)
form.utf8 = "&#x2713;"
form.authenticity_token = token
form.from = "email_login"
form.email = email
form.password = password
button = form.button_with(:id => 'user-login-btn')

# Submit the form
page = form.submit(button)

puts "Current page : " + page.title + " | URL : " + page.uri.to_s
puts "-----------------------------------"

# Once we are redirected, store the session cookie
session_cookie = agent.cookie_jar


# Call the function to update the calendar
update_calendar(  :session_cookie => session_cookie,
                  :room_id        => room_id,
                  :start_date     => DateTime.now.strftime("%F"),
                  :end_date       => DateTime.now.strftime("%F"),
                  :price          => 506,
                  :note           => "This room is awesome !!!",
                  :availability   => "available"
                )
