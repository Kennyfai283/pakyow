# frozen_string_literal: true

require "pakyow/process"
require "pakyow/processes/server"

module Pakyow
  module Assets
    # Manages the webpack process.
    #
    class Process < Process
      dependent_on Processes::Server

      def initialize(server, app)
        super(server)
        @app = app
      end

      def start
        Thread.new do
          webpack = IO.popen("PAKYOW_ASSETS_CONFIG='#{Base64.encode64(@app.config.assets.to_hash.to_json)}' #{@app.config.assets.webpack_command} --watch")
          @pid = webpack.pid

          # Filter annoying output (yes this is unreasonable).
          #
          webpack.each do |line|
            next if line == "Webpack is watching the files…\n" || line.strip.empty?
            Pakyow.logger << line
          end
        end

        # TODO: in the future, we may also start the webpack-dev-server based on config options
        super
      end

      protected

      def watch_callback(modified, added, removed)
        if restart?(modified, added, removed)
          @app.build_packs
          restart
        end
      end

      def restart?(_modified, added, removed)
        return true if (added + removed).find { |path|
          @app.config.assets.extensions.include?(File.extname(path))
        }

        false
      end
    end
  end
end
