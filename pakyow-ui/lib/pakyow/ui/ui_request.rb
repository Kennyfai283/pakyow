# frozen_string_literal: true

module Pakyow
  module UI
    # A simple request object used for accessing the session.
    #
    # @api private
    class UIRequest
      attr_reader :session

      def initialize(session)
        @session = Hash.strhash(session)
      end
    end
  end
end
