RSpec.describe "halting a request" do
  include_context "testable app"

  context "when halting from a route" do
    let :app_definition do
      Proc.new {
        router do
          default do
            $called = true
            halt
            $halted = false
          end
        end
      }
    end

    before do
      $called = false
      $halted = true
    end

    it "immediately halts and returns the response" do
      call
      expect($called).to be(true)
      expect($halted).to be(true)
    end
  end

  context "when halting from a hook" do
    let :app_definition do
      Proc.new {
        router do
          def hook
            $hooked = true
            halt
          end

          default before: [:hook] do
            $halted = false
          end
        end
      }
    end

    before do
      $hooked = false
      $halted = true
    end

    it "immediately halts and returns the response" do
      call
      expect($hooked).to be(true)
      expect($halted).to be(true)
    end
  end

  context "when halting with a body" do
    let :app_definition do
      Proc.new {
        router do
          default do
            halt "foo"
          end
        end
      }
    end

    it "sets the response body, halts, and returns the response" do
      expect(call[2].body).to eq("foo")
    end
  end

  context "when halting in a before process hook" do
    let :app_definition do
      Proc.new {
        router do
          default do
          end
        end
      }
    end

    using Pakyow::Support::DeepDup

    before do
      @hook_hash = Pakyow::Controller.instance_variable_get(:@hook_hash).deep_dup
      @pipeline = Pakyow::Controller.instance_variable_get(:@pipeline).deep_dup

      Pakyow::Controller.before :process do
        halt "foo"
      end
    end

    after do
      Pakyow::Controller.instance_variable_set(:@hook_hash, @hook_hash)
      Pakyow::Controller.instance_variable_set(:@pipeline, @pipeline)
    end

    it "sets the response body, halts, and returns the response" do
      expect(call[2].body).to eq("foo")
    end
  end
end