require_relative "shared_examples/associations"
require_relative "shared_examples/commands"
require_relative "shared_examples/connection"
require_relative "shared_examples/queries"
require_relative "shared_examples/qualifications"
require_relative "shared_examples/results"
require_relative "shared_examples/schema"
require_relative "shared_examples/setup"

RSpec.describe "postgres model" do
  include_examples :model_associations
  include_examples :model_commands
  include_examples :model_connection
  include_examples :model_queries
  include_examples :model_qualifications
  include_examples :model_results
  include_examples :model_schema
  include_examples :model_setup

  let :connection_string do
    "postgres://localhost/pakyow-test"
  end

  before do
    if system("psql -lqt | cut -d \\| -f 1 | grep -qw pakyow-test")
      system "psql pakyow-test -c 'DROP SCHEMA public CASCADE' > /dev/null", out: File::NULL, err: File::NULL
      system "psql pakyow-test -c 'CREATE SCHEMA public' > /dev/null", out: File::NULL, err: File::NULL
    else
      system "createdb pakyow-test > /dev/null", out: File::NULL, err: File::NULL
    end
  end

  describe "postgres-specific types" do
    it "needs to be defined"
  end
end