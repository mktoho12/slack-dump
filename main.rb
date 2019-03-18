require 'slack'
require 'json'
require 'csv'

client = Slack::Client.new token: ENV['SLACK_TOKEN']

users = Hash[client.users_list['members'].map{ |m| [m['id'], m['profile']['real_name']] }]

channels = Hash[client.conversations_list(types: 'private_channel')['channels'].map{ |m| [m['id'], m['name']] }]

messages = Hash[channels.map do |id, name|
  messages = []
  response = {}
  loop do
    response = client.conversations_history(channel: id, limit: 1000, cursor: response.fetch('response_metadata', {})['next_cursor'] )
    messages += response['messages']
    break unless response['has_more']
  end
  [id, messages]
end]
IO.write 'dump.txt', JSON.pretty_generate(messages)

talk = Hash[messages.map do |k,v|
  [channels[k], v.map do |m|
    {
      name: users[m['user']],
      ts: Time.at(m['ts'].to_i),
      text: m['text'].gsub(/<@(.*)>/) {"@#{users[$1]}"}
    }
  end.reverse]
end]
IO.write 'users.json', JSON.pretty_generate(users)
IO.write 'channels.json', JSON.pretty_generate(channels)
IO.write 'talk.json', JSON.pretty_generate(talk)
IO.write 'users_raw.json', JSON.pretty_generate(client.users_list)
IO.write 'talk.csv', talk.map{ |k,v| v.map{|m| CSV.generate_line [k, m[:name], m[:ts], m[:text]], col_sep: "\t" }.join }.join("\n")
