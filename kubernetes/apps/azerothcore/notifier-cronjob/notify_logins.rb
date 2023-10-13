require "json"
require "mysql2"
require "telegram/bot"

def maybe_notify(user_login_last_status, user_login_current_status)
  account_id = user_login_current_status.fetch("id")
  username = user_login_current_status.fetch("username")
  user_online_current_status = user_login_current_status.fetch("online")
  user_online_last_status = user_login_last_status.fetch("online")

  puts "Account ID #{account_id}: previous status #{user_online_last_status}, current status #{user_online_current_status}"
  if user_online_last_status == 0 && user_online_current_status == 1
    puts "Account ID #{account_id}: seems user #{username} has come online, will notify"
    text = "Azerothcore: Account ID #{account_id}, user #{username} has come online"
  elsif user_online_last_status == 1 && user_online_current_status == 0
    puts "Account ID #{account_id}: seems user #{username} has gone offline, will notify"
    text = "Azerothcore: Account ID #{account_id}, user #{username} has gone offline"
  else
    puts "Account ID #{account_id}: seems user #{username} is status quo, will do nothing"
    return
  end

  Telegram.bot.send_message(chat_id: telegram_chat_id, text: text)
end

puts "Beginning setup"

last_login_data_file = ENV.fetch("LAST_LOGIN_DATA_FILE")
mysql_host = ENV.fetch("MYSQL_HOST", "mysql")
mysql_port = ENV.fetch("MYSQL_PORT", 3306)
mysql_user = ENV.fetch("MYSQL_USER", "root")
mysql_password = ENV.fetch("MYSQL_PASSWORD")
telegram_chat_id = ENV.fetch("TELEGRAM_CHAT_ID")
telegram_token = ENV.fetch("TELEGRAM_TOKEN")

Telegram.bots_config = { default: telegram_token }

# Telegram.bot.get_updates

puts "Connecting to MySQL database"

client = Mysql2::Client.new(host: mysql_host, port: mysql_port, username: mysql_user, password: mysql_password, database: "acoreauth")

puts "Checking for last login data file"
if File.exist?(last_login_data_file)
  puts "Last login data file found, reading"
  last_login_data = JSON.parse(File.read(last_login_data_file))
else
  puts "Last login data file not found, using empty buffer"
  last_login_data = []
end

puts "Querying accounts"
new_login_data = client.query("SELECT id, last_login, username, online FROM account").map do |row|
  account_id = row.fetch("id")
  username = row.fetch("username")

  puts "Account ID #{account_id}: Checking username #{username}"
  user_login_last_status = last_login_data.find { |item| item.fetch("id") == account_id }
  if user_login_last_status
    last_login = row.fetch("last_login")
    puts "Account ID #{account_id}: last login at #{last_login.nil? ? "<never>" : last_login}"
    maybe_notify(user_login_last_status, row.to_h)
  else
    puts "Account ID #{account_id}: no last status found"
  end
  row.to_h
end

puts "Writing current login status to file"
File.write(last_login_data_file, new_login_data.to_json)

puts "Finished"
