require "pakyow/support/silenceable"
Pakyow::Support::Silenceable.silence_warnings do
  require "oga"
end

require "pakyow/presenter/presenter"

require "pakyow/presenter/string_doc"
require "pakyow/presenter/string_node"
require "pakyow/presenter/string_attributes"
require "pakyow/presenter/significant"

require "pakyow/presenter/view"
require "pakyow/presenter/attributes"
require "pakyow/presenter/versioned_view"

require "pakyow/presenter/template_store"
require "pakyow/presenter/front_matter_parser"
require "pakyow/presenter/processor"
require "pakyow/presenter/binder"

require "pakyow/presenter/views/form"
require "pakyow/presenter/views/layout"
require "pakyow/presenter/views/page"
require "pakyow/presenter/views/container"
require "pakyow/presenter/views/partial"

require "pakyow/presenter/presenters/form"
require "pakyow/presenter/presenters/view"

require "pakyow/presenter/extensions/app"
require "pakyow/presenter/extensions/controller"
require "pakyow/presenter/extensions/router"

require "pakyow/presenter/exceptions"
require "pakyow/presenter/helpers"
