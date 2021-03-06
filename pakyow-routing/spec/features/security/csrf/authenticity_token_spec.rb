RSpec.describe "verifying the request's authenticity token" do
  include_context "testable app"

  before do
    allow_any_instance_of(
      Pakyow::Security::CSRF::VerifySameOrigin
    ).to receive(:allowed?).and_return(true)
  end

  let :app_definition do
    Proc.new do
      controller do
        get "/" do
          $authenticity_client_id = authenticity_client_id
          $authenticity_digest = authenticity_digest(authenticity_client_id)
        end

        post "/" do
        end
      end
    end
  end

  context "authenticity token is passed" do
    context "authenticity token is valid" do
      it "accepts the request" do
        cookie = call("/")[1]["Set-Cookie"]

        expect(
          call(
            "/",
            method: :post,
            "HTTP_COOKIE" => cookie,
            params: {
              authenticity_token: "#{$authenticity_client_id}:#{$authenticity_digest}"
            }
          )[0]
        ).to eq(200)
      end
    end

    context "authenticity token is invalid" do
      it "rejects the request" do
        expect(call("/", method: :post, params: { authenticity_token: "123:321" })[0]).to eq(403)
      end
    end
  end

  context "authenticity token is not passed" do
    it "rejects the request" do
      expect(call("/", method: :post)[0]).to eq(403)
    end
  end

  describe "skipping verify_authenticity_token" do
    let :app_definition do
      Proc.new do
        controller do
          skip_action :verify_authenticity_token

          post "/" do
          end
        end
      end
    end

    it "skips" do
      expect(call("/", method: :post)[0]).to eq(200)
    end
  end

  describe "overriding verify_authenticity_token" do
    let :app_definition do
      Proc.new do
        controller do
          post "/" do
          end

          def verify_authenticity_token
            send "overridden"
          end
        end
      end
    end

    it "overrides" do
      expect(call("/", method: :post)[2].body.read).to eq("overridden")
    end
  end
end
