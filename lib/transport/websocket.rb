# frozen_string_literal: true

module SlackSocketModeBot
  module Transport
    # This class heavily leverages async and async-websocket to keep a connection alive to the
    # URL provided by the client
    # It will perform as expected for a Slack Socket Mode client: acknowledge all events and refresh when needed
    # Moreover it will use the client's callback for processing events
    class WebSocket
      attr_reader :client

      def initialize(client:, logger: nil)
        @client = client
        @logger = logger || Logger.new($stdout)

        @restart = Async::Notification.new
        @ping_id = 1
      end

      # rubocop:disable Metrics
      def connect!
        Async do |task|
          trap_sigterm(task)

          loop do
            endpoint = Async::HTTP::Endpoint.parse(client.new_socket_url)

            Async::WebSocket::Client.connect(endpoint) do |connection|
              @ping_task = task.async do |subtask|
                subtask.annotate "socket keep-alive"

                loop do
                  subtask.sleep 50
                  ping!(connection) if @restart
                end
              end

              @socket_task&.stop
              @socket_task = task.async do |subtask|
                subtask.annotate "socket message loop"

                message_loop(connection)
              rescue StandardError => e
                @logger.info("Message read failed: #{e.message}. Restarting the socket")
                restart!
              end

              # Wait here letting it ping & process messages until we need to reconnect
              @restart.wait
            end
          end
        end
      rescue Interrupt
        puts "Interrupt detected. Exiting..."
      ensure
        @ping_task&.stop
        @socket_task&.stop
      end
      # rubocop:enable Metrics

      private

      def message_loop(connection)
        while (message = connection.read)
          parsed = JSON.parse(message, symbolize_names: true)

          @logger.debug("Got #{parsed.dig(:payload, :event, :type) || parsed}")

          # Acknowledge all events
          ack_event(connection, parsed[:envelope_id]) if parsed[:envelope_id]

          # Restart when we get the warning to minimise downtime
          restart! if parsed[:type] == "disconnect"

          client.callback(parsed[:payload]) if parsed[:payload]
        end
      end

      def restart!
        @ping_task&.stop
        @ping_id = 1

        @restart.signal
      end

      def ping!(connection)
        @logger.debug("Sending ping #{@ping_id}")
        connection.send_ping("id=#{@ping_id}")
        connection.flush

        @ping_id += 1
      rescue StandardError => e
        @logger.info("Ping failed: #{e.message}. Restarting the socket")
        restart!
      end

      def ack_event(connection, envelope_id)
        connection.write(
          Protocol::WebSocket::TextMessage.generate({ envelope_id: envelope_id })
        )
        connection.flush
      end

      def trap_sigterm(task)
        Signal.trap("SIGTERM") do
          puts("Received SIGTERM. Exiting...") # can't log from signal handler
          @ping_task&.stop
          @socket_task&.stop
          task&.stop
        end
      rescue StandardError => e
        puts("Error processing SIGTERM handler: #{e.message}")
      end
    end
  end
end
