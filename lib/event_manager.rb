# frozen_string_literal: true

require "csv"
require "google/apis/civicinfo_v2"
require "erb"

def clean_zipcodes(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def clean_phone_number(number)
  clean_number = number.tr("-(). ", "")
  if clean_number.length == 10
    clean_number
  elsif clean_number.length == 11 && clean_number[0] == "1"
    clean_number[1..11]
  else
    "Invalid Phone Number"
  end
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: "country",
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exist?("output")
  filename = "output/thanks_#{id}.html"
  File.open(filename, "w") { |file| file.puts form_letter }
end

puts "EventManager initalized"

numbers_for_alerts = []

if File.exist? "event_attendees.csv"
  contents = CSV.open("event_attendees.csv", headers: true, header_converters: :symbol)
  template_letter = File.read("form_letter.erb")
  template = ERB.new template_letter
  contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcodes(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)
    results = template.result(binding)
    save_thank_you_letter(id, results)
    phone = clean_phone_number(row[:homephone])
    numbers_for_alerts.push(phone) unless phone == "Invalid Phone Number"
  end
end

puts numbers_for_alerts
