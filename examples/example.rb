# frozen_string_literal: true

require "slack-ruby-socket-mode-bot"

logger = Logger.new($stdout)
logger.level = :warn

bot = SlackSocketModeBot::Bot.new(
  bot_token: ENV.fetch("SLACK_BOT_TOKEN"),
  app_token: ENV.fetch("SLACK_APP_TOKEN"),
  logger: logger
)

# Answers "pong" in a thread
bot.on(/ping/) do |event, _match_data, client|
  client.chat_postMessage(
    channel: event[:channel],
    text: "pong",
    thread_ts: event[:ts]
  )
end

# Responds with the first word after the command, reversed
bot.on(/mirror (?<word>\w+)/) do |event, match_data, client|
  client.chat_postMessage(
    channel: event[:channel],
    text: match_data[:word].reverse
  )
end

# Greets the user with a mention
bot.on(/hi/) do |event, _match_data, client|
  client.chat_postMessage(
    channel: event[:channel],
    text: "Hi, <@#{event[:user]}>!"
  )
end
bot.run!
