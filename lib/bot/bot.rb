# frozen_string_literal: true

module SlackSocketModeBot
  MentionHandler = Data.define(:match_regex, :callback)

  # Entry class for the gem, allows registering callbacks that will be triggered
  # when the bot is mentioned
  class Bot
    def initialize(bot_token:, app_token:, logger: nil)
      @bot_token = bot_token
      @logger = logger || Logger.new($stdout)

      slack_web_client # init

      @socket_mode_client = Transport::SocketModeClient.new(
        app_token:, logger:, callback: method(:process_event)
      )
    end

    # Registers a callback for a matching regex
    def on(match_regex, &block)
      (@handlers ||= []) << MentionHandler.new(match_regex, block)
    end

    def run!
      @socket_mode_client.run!
    end

    private

    def slack_web_client
      client = Slack::Web::Client.new(token: @bot_token)
      auth_response = client.auth_test

      raise auth_response unless auth_response[:ok]

      @bot_user_id = auth_response[:user_id]
      @team_id = auth_response[:team_id]

      @slack_web_client ||= client
    end

    def handle_error(err)
      @logger.error(err.message)
      @logger.debug(err.backtrace)
    end

    def process_event(payload)
      return unless payload_processable?(payload)

      text_without_mention = payload[:event][:text].gsub(/<@#{@bot_user_id}>\s+/, "")

      @handlers.each do |handler|
        process_handler(handler, text_without_mention, payload[:event])
      end
    rescue StandardError => e
      # Don't bring down the bot from a problematic message
      handle_error(e)
    end

    def payload_processable?(payload)
      if payload[:team_id] != @team_id
        raise UnrecognisedWorkspace.new, "Unrecognised team id #{payload[:team_id]} (expected #{@team_id})"
      end

      payload[:event][:type] == "app_mention"
    end

    def process_handler(handler, text, event)
      if (match_data = handler.match_regex.match(text))
        @logger.debug("Found matching handler for #{match_data}")
        handler.callback.call(event, match_data, slack_web_client)
      end
    rescue StandardError => e
      # Don't stop processing handlers if one of them fails
      handle_error(e)
    end
  end
end
