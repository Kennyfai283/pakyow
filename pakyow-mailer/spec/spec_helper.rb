start_simplecov do
  lib_path = File.expand_path("../../lib", __FILE__)

  add_filter do |file|
    !file.filename.start_with?(lib_path)
  end

  track_files File.join(lib_path, "**/*.rb")
end

require "pakyow/routing"
require "pakyow/presenter"
require "pakyow/mailer"

require_relative "../../spec/helpers/app_helpers"
require_relative "../../spec/helpers/mock_handler"

RSpec.configure do |config|
  config.include AppHelpers
end

require_relative "../../spec/context/testable_app_context"
require_relative "../../spec/context/suppressed_output_context"

$mailer_app_boilerplate = Proc.new do
  config.presenter.path = File.join(File.expand_path("../", __FILE__), "features/support/views")
end
