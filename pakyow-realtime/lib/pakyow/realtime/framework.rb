# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/realtime/helpers/broadcasting"
require "pakyow/realtime/helpers/subscriptions"
require "pakyow/realtime/helpers/socket"

require "pakyow/realtime/behavior/config"
require "pakyow/realtime/behavior/rendering"
require "pakyow/realtime/behavior/server"
require "pakyow/realtime/behavior/silencing"

require "pakyow/realtime/actions/upgrader"

module Pakyow
  module Realtime
    class Framework < Pakyow::Framework(:realtime)
      def boot
        object.class_eval do
          action Actions::Upgrader

          register_helper :active, Helpers::Broadcasting
          register_helper :active, Helpers::Subscriptions
          register_helper :passive, Helpers::Socket

          # Socket events are triggered on the app.
          #
          events :join, :leave

          include Behavior::Config
          include Behavior::Rendering
          include Behavior::Server
          include Behavior::Silencing
        end
      end
    end
  end
end
