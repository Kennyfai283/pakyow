# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Assets
    module Behavior
      module Watching
        extend Support::Extension

        apply_extension do
          after :load do
            config.assets.extensions.each do |extension|
              config.process.watched_paths << File.join(config.presenter.path, "**/*#{extension}")

              # Exclude vendored assets.
              #
              config.process.excluded_paths << File.join(config.assets.externals.path, "*#{extension}")
            end
          end
        end
      end
    end
  end
end
