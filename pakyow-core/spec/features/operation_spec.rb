RSpec.describe "operation" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      operation :test do
        attr_reader :foo_result, :bar_result

        action :foo do
          @foo_result = @values[:foo].reverse
        end

        action :bar do
          @bar_result = @values[:bar].reverse
        end
      end
    }
  end

  it "can be called with values" do
    Pakyow.app(:test).operations.test(foo: "foo", bar: "bar").tap do |result|
      expect(result.foo_result).to eq("oof")
      expect(result.bar_result).to eq("rab")
    end
  end
end
