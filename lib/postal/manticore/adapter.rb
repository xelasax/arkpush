# frozen_string_literal: true

require "mysql2"

module Postal
  module Manticore
    class Adapter

      class << self

        def enabled?
          Postal::Config.manticore&.enabled == true
        end

        def client
          @client ||= begin
            config = Postal::Config.manticore
            Mysql2::Client.new(
              host: config.host || "127.0.0.1",
              port: config.port || 9306,
              username: config.username,
              password: config.password,
              connect_timeout: 2
            )
          rescue StandardError => e
            Rails.logger.error "Failed to connect to Manticore: #{e.message}"
            nil
          end
        end

        def query(sql)
          return nil unless client

          client.query(sql)
        rescue StandardError => e
          Rails.logger.error "Manticore Query Error: #{e.message} (SQL: #{sql})"
          @client = nil # Force reconnect on next try
          nil
        end

        def escape(value)
          client ? client.escape(value.to_s) : value.to_s.gsub("'", "''")
        end

        def index_name(server_id)
          "postal_messages_server_#{server_id}"
        end

      end

    end
  end
end
