require "pakyow/plugin"

RSpec.describe "rendering view templates" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
    end
  end

  after do
    Object.send(:remove_const, :TestPlugin)
  end

  include_context "testable app"

  shared_examples :plugin_rendering do
    context "endpoint is unavailable for the request, but a template matches" do
      it "renders the view template" do
        call(File.join(mount_path, "test-plugin/render")).tap do |result|
          expect(result[0]).to eq(200)
          response_body = result[2].body.read
          expect(response_body).to include_sans_whitespace(
            <<~HTML
              <title>app default</title>
            HTML
          )

          expect(response_body).to include_sans_whitespace(
            <<~HTML
              plugin render
            HTML
          )
        end
      end
    end

    context "endpoint renders" do
      it "renders the view template" do
        call(File.join(mount_path, "test-plugin/render/explicit")).tap do |result|
          expect(result[0]).to eq(200)
          response_body = result[2].body.read
          expect(response_body).to include_sans_whitespace(
            <<~HTML
              <title>app default</title>
            HTML
          )

          expect(response_body).to include_sans_whitespace(
            <<~HTML
              plugin render
            HTML
          )
        end
      end
    end

    context "endpoint does not explicitly render, but a template matches" do
      it "404s, because implicit rendering is unsupported" do
        call(File.join(mount_path, "test-plugin/render/implicit")).tap do |result|
          expect(result[0]).to eq(404)
        end
      end
    end

    context "app overrides the view template" do
      it "renders the app view template" do
        call(File.join(mount_path, "test-plugin/render/app-override")).tap do |result|
          expect(result[0]).to eq(200)
          response_body = result[2].body.read
          expect(response_body).to include_sans_whitespace(
            <<~HTML
              <title>app default</title>
            HTML
          )

          expect(response_body).to include_sans_whitespace(
            <<~HTML
              app render
            HTML
          )
        end
      end

      context "app view template includes partials from the app" do
        it "renders properly" do
          call(File.join(mount_path, "test-plugin/render/app-override-with-partials")).tap do |result|
            expect(result[0]).to eq(200)
            response_body = result[2].body.read
            expect(response_body).to include_sans_whitespace(
              <<~HTML
                <title>app default</title>
              HTML
            )

            expect(response_body).to include_sans_whitespace(
              <<~HTML
                app render
              HTML
            )

            expect(response_body).to include_sans_whitespace(
              <<~HTML
                app partial
              HTML
            )
          end
        end
      end

      context "app view template includes global partials from the app" do
        it "renders properly" do
          call(File.join(mount_path, "test-plugin/render/app-override-with-global-partials")).tap do |result|
            expect(result[0]).to eq(200)
            response_body = result[2].body.read
            expect(response_body).to include_sans_whitespace(
              <<~HTML
                <title>app default</title>
              HTML
            )

            expect(response_body).to include_sans_whitespace(
              <<~HTML
                app render
              HTML
            )

            expect(response_body).to include_sans_whitespace(
              <<~HTML
                app global partial
              HTML
            )
          end
        end
      end

      context "app view template includes the plugin view" do
        it "renders properly" do
          call(File.join(mount_path, "test-plugin/render/app-include-plugin-view")).tap do |result|
            expect(result[0]).to eq(200)
            response_body = result[2].body.read
            expect(response_body).to include_sans_whitespace(
              <<~HTML
                <title>app default</title>
              HTML
            )

            expect(response_body).to include_sans_whitespace(
              <<~HTML
                app render
              HTML
            )

            expect(response_body).to include_sans_whitespace(
              <<~HTML
                plugin render
              HTML
            )
          end
        end

        context "both templates include partials" do
          it "renders properly" do
            call(File.join(mount_path, "test-plugin/render/app-include-plugin-view-with-partials")).tap do |result|
              expect(result[0]).to eq(200)
              response_body = result[2].body.read
              expect(response_body).to include_sans_whitespace(
                <<~HTML
                  <title>app default</title>
                HTML
              )

              expect(response_body).to include_sans_whitespace(
                <<~HTML
                  app render
                HTML
              )

              expect(response_body).to include_sans_whitespace(
                <<~HTML
                  app partial
                HTML
              )

              expect(response_body).to include_sans_whitespace(
                <<~HTML
                  app global partial
                HTML
              )

              expect(response_body).to include_sans_whitespace(
                <<~HTML
                  plugin render
                HTML
              )

              expect(response_body).to include_sans_whitespace(
                <<~HTML
                  plugin other_partial
                HTML
              )

              expect(response_body).to include_sans_whitespace(
                <<~HTML
                  plugin global other_partial
                HTML
              )
            end
          end
        end
      end
    end

    context "plugin renders with a layout missing from the app" do
      it "renders with the plugin layout" do
        call(File.join(mount_path, "test-plugin/render/plugin-layout")).tap do |result|
          expect(result[0]).to eq(200)
          response_body = result[2].body.read
          expect(response_body).to include_sans_whitespace(
            <<~HTML
              <title>plugin special</title>
            HTML
          )

          expect(response_body).to include_sans_whitespace(
            <<~HTML
              plugin render
            HTML
          )
        end
      end

      context "app overrides the view template" do
        it "renders the app view template in the plugin layout" do
          call(File.join(mount_path, "test-plugin/render/app-override-plugin-layout")).tap do |result|
            expect(result[0]).to eq(200)
            response_body = result[2].body.read
            expect(response_body).to include_sans_whitespace(
              <<~HTML
                <title>plugin special</title>
              HTML
            )

            expect(response_body).to include_sans_whitespace(
              <<~HTML
                app render
              HTML
            )
          end
        end
      end
    end
  end

  context "mounted at the root path" do
    let :app_definition do
      Proc.new {
        plug :testable, at: "/"

        configure :test do
          config.root = File.join(__dir__, "support/app")
        end
      }
    end

    let :mount_path do
      "/"
    end

    include_examples :plugin_rendering
  end

  context "mounted at a non-root path" do
    let :app_definition do
      Proc.new {
        plug :testable, at: "/foo"

        configure :test do
          config.root = File.join(__dir__, "support/app")
        end
      }
    end

    let :mount_path do
      "/foo"
    end

    include_examples :plugin_rendering
  end
end
