require 'rubygems'
require 'twilio-ruby'
require 'yaml'
 
keys = YAML.load_file("./keys.yaml")

account_sid = keys['account_sid']
auth_token = keys['auth_token']

client = Twilio::REST::Client.new account_sid, auth_token
 
from =  keys['number_from']
 
#friends = {
#"+16158525850" => "Virgil",
#"+16154825480" => "Veronica"
#}

keys['friends'].each do |key, value|
  puts "#{key} => #{value}"
  client.account.messages.create(
    :from => from,
    :to => value,
    :body => keys['message']  
  )
  puts "Sent message to #{key}"
end
