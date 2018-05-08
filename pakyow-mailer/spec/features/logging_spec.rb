RSpec.describe "logging outgoing mail" do
  include_context "testable app"

  context "logging is enabled" do
    let :app_definition do
      Proc.new do
        instance_exec(&$mailer_app_boilerplate)

        configure :test do
          config.mailer.log_outgoing = true
        end

        controller "/mail" do
          get "/send/:email/:subject" do
            mailer("mail/simple").deliver_to(
              params[:email], subject: params[:subject]
            )
          end
        end
      end
    end

    it "logs" do
      expect_any_instance_of(Pakyow::Logger::RequestLogger).to receive(:debug).with <<~LOG
      ┌──────────────────────────────────────────────────────────────────────────────┐
      │ Subject: logtest                                                             │
      ├──────────────────────────────────────────────────────────────────────────────┤
      │ test mail                                                                    │
      ├──────────────────────────────────────────────────────────────────────────────┤
      │ → bryan@bryanp.org                                                           │
      └──────────────────────────────────────────────────────────────────────────────┘
      LOG

      expect(call("mail/send/bryan@bryanp.org/logtest")[0]).to eq(200)
    end
  end

  context "logging is disabled" do
    let :app_definition do
      Proc.new do
        instance_exec(&$mailer_app_boilerplate)

        configure :test do
          config.mailer.log_outgoing = false
        end

        controller "/mail" do
          get "/send/:email/:subject" do
            mailer("mail/simple").deliver_to(
              params[:email], subject: params[:subject]
            )
          end
        end
      end
    end

    it "does not log" do
      expect_any_instance_of(Pakyow::Logger::RequestLogger).not_to receive(:debug)
      expect(call("mail/send/bryan@bryanp.org/logtest")[0]).to eq(200)
    end
  end
end
