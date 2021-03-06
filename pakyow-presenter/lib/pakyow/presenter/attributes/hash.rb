# frozen_string_literal: true

require "forwardable"

require "pakyow/presenter/attributes/attribute"

module Pakyow
  module Presenter
    class Attributes
      # Wraps the value for a hash-type view attribute (e.g. style).
      #
      # Behaves just like a normal +Hash+.
      #
      class Hash < Attribute
        VALUE_SEPARATOR = ":".freeze
        PAIR_SEPARATOR  = ";".freeze

        WRITE_VALUE_SEPARATOR = ": ".freeze
        WRITE_PAIR_SEPARATOR  = "; ".freeze

        extend Forwardable
        def_delegators :@value, :any?, :empty?, :include?, :key?, :value?, :[], :[]=, :delete, :clear

        def to_s
          string_value = @value.to_a.map { |value|
            value.join(WRITE_VALUE_SEPARATOR)
          }.join(WRITE_PAIR_SEPARATOR)

          string_value.empty? ? string_value : string_value + PAIR_SEPARATOR
        end

        class << self
          def parse(value)
            if value.is_a?(::Hash)
              new(value)
            elsif value.respond_to?(:to_s)
              new(value.to_s.split(PAIR_SEPARATOR).each_with_object({}) { |style, attributes|
                key, value = style.split(VALUE_SEPARATOR)
                next unless key && value
                attributes[key.strip.to_sym] = value.strip
              })
            else
              raise ArgumentError.new("Expected value to be a Hash or String")
            end
          end
        end
      end
    end
  end
end
