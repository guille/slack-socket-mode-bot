# frozen_string_literal: true

module SlackSocketModeBot
  module Transport
    class SocketModeClient
      def initialize(app_token:, callback:, logger: nil)
        @app_token = app_token
        @callback = callback
        @logger = logger || Logger.new($stdout)

        @socket = WebSocket.new(client: self, logger: @logger)
      end

      def run!
        @socket.connect!
      end

      def new_socket_url
        response = slack_web_client.apps_connections_open

        raise response unless response[:ok]

        response[:url]
        # debug only:
        "#{response[:url]}&debug_reconnects=true"
      end

      def callback(*args)
        @callback.call(*args)
      end

      private

      def slack_web_client
        client = Slack::Web::Client.new(
          token: @app_token,
          logger: @logger
        )
        @slack_web_client ||= client
      end
    end
  end
end
