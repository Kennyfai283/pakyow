RSpec.describe "response headers for assets" do
  include_context "testable app"

  let :app_definition do
    Proc.new do
      instance_exec(&$assets_app_boilerplate)
    end
  end

  it "sets Content-Length" do
    expect(call("/default.css")[1]["Content-Length"]).to eq(31)
  end

  it "sets Content-Type" do
    expect(call("/default.css")[1]["Content-Type"]).to eq("text/css")
  end

  context "asset is a pack" do
    it "sets Content-Length" do
      expect(call("/assets/packs/versioned.js")[1]["Content-Length"]).to eq(34)
    end

    it "sets Content-Type" do
      expect(call("/assets/packs/versioned.js")[1]["Content-Type"]).to eq("application/javascript")
    end
  end

  context "asset is a public file" do
    it "sets Content-Length" do
      expect(call("/robots.txt")[1]["Content-Length"]).to eq(23)
    end

    it "sets Content-Type" do
      expect(call("/robots.txt")[1]["Content-Type"]).to eq("text/plain")
    end
  end
end
