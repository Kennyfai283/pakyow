RSpec.describe "mailer helpers" do
  include_examples "testable app"

  it "registers Mailer::Helpers as an active helper" do
    expect(app.helpers(:active)).to include(Pakyow::Mailer::Helpers)
  end
end
