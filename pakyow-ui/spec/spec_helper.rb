require_relative '../../pakyow-support/lib/pakyow-support'
require_relative '../../pakyow-core/lib/pakyow-core'
require_relative '../../pakyow-presenter/lib/pakyow-presenter'
require_relative '../../pakyow-realtime/lib/pakyow-realtime'

require 'rack/test'

# disable the logger when staging
Pakyow::App.after :init do
  Pakyow.logger = Rack::NullLogger.new(self)
end

# handle errors that occur
Pakyow::CallContext.after :error do
  # puts request.error.message
  # puts request.error.backtrace

  fail request.error
end

if ENV['COVERAGE']
  require 'simplecov'
  require 'simplecov-console'
  SimpleCov.formatter = SimpleCov::Formatter::Console
  SimpleCov.start
end

module PerformedMutations
  def self.perform(name, view = nil, data = nil)
    performed(name) << {
      view: view,
      data: data
    }

    view
  end

  def self.performed(name = nil)
    @performed ||= {}

    return @performed if name.nil?
    @performed[name] ||= []
  end

  def self.reset
    @performed = {}
  end
end
