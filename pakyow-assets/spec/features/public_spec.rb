RSpec.describe "accessing public files" do
  include_context "testable app"

  context "public handling is enabled" do
    let :app_definition do
      Proc.new do
        instance_exec(&$assets_app_boilerplate)
        config.assets.public = true
      end
    end

    context "requested file exists" do
      it "responds 200" do
        expect(call("/robots.txt")[0]).to eq(200)
      end

      it "responds with the file" do
        expect(call("/robots.txt")[2].body.read).to eq("User-agent: *\nAllow: /\n")
      end
    end

    context "requested file does not exist" do
      it "responds 404" do
        expect(call("/nonexistent")[0]).to eq(404)
      end
    end
  end

  context "public handling is disabled" do
    let :app_definition do
      Proc.new do
        instance_exec(&$assets_app_boilerplate)
        config.assets.public = false
      end
    end

    context "requested file exists" do
      it "responds 404" do
        expect(call("/robots.txt")[0]).to eq(404)
      end
    end

    context "requested file does not exist" do
      it "responds 404" do
        expect(call("/nonexistent")[0]).to eq(404)
      end
    end
  end
end
