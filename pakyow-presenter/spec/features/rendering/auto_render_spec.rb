RSpec.describe "auto rendering" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      instance_exec(&$presenter_app_boilerplate)

      controller :default do
        get "/other" do; end
      end
    }
  end

  context "view exists" do
    it "automatically renders the view" do
      response = call("/other")
      expect(response[0]).to eq(200)
      expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    other\n\n  </body>\n</html>\n")
    end

    context "presenter is defined" do
      let :app_definition do
        Proc.new {
          instance_exec(&$presenter_app_boilerplate)

          controller :default do
            get "/other" do; end
          end

          presenter "/other" do
            def perform
              self.title = "invoked"
            end
          end
        }
      end

      it "invokes the defined presenter" do
        response = call("/other")
        expect(response[0]).to eq(200)
        expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>invoked</title>\n  </head>\n\n  <body>\n    other\n\n  </body>\n</html>\n")
      end
    end

    context "exposures are defined in the controller" do
      let :app_definition do
        Proc.new {
          instance_exec(&$presenter_app_boilerplate)

          controller :default do
            get "/exposure" do
              expose :post, { title: "foo" }
            end
          end
        }
      end

      it "finds and presents each exposure" do
        expect(call("/exposure")[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    <div data-b=\"post\">\n  <h1 data-b=\"title\">foo</h1>\n</div><script type=\"text/template\" data-b=\"post\"><div data-b=\"post\">\n  <h1 data-b=\"title\">title goes here</h1>\n</div></script>\n\n  </body>\n</html>\n")
      end

      context "exposure is plural" do
        let :app_definition do
          Proc.new {
            instance_exec(&$presenter_app_boilerplate)

            controller :default do
              get "/exposure" do
                expose :posts, [{ title: "foo" }, { title: "bar" }]
              end
            end
          }
        end

        it "finds and presents to the singular version" do
          expect(call("/exposure")[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    <div data-b=\"post\">\n  <h1 data-b=\"title\">foo</h1>\n</div><div data-b=\"post\">\n  <h1 data-b=\"title\">bar</h1>\n</div><script type=\"text/template\" data-b=\"post\"><div data-b=\"post\">\n  <h1 data-b=\"title\">title goes here</h1>\n</div></script>\n\n  </body>\n</html>\n")
        end
      end

      context "exposure is channeled" do
        let :app_definition do
          Proc.new {
            instance_exec(&$presenter_app_boilerplate)

            controller :default do
              get "/exposure/channeled" do
                expose :post, { title: "foo" }, for: :foo
                expose :post, { title: "bar" }, for: :bar
              end
            end
          }
        end

        it "finds and presents each channeled version" do
          expect(call("/exposure/channeled")[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    <div data-b=\"post\" data-c=\"foo\">\n  foo\n  <h1 data-b=\"title\">foo</h1>\n</div><script type=\"text/template\" data-b=\"post\" data-c=\"foo\"><div data-b=\"post\" data-c=\"foo\">\n  foo\n  <h1 data-b=\"title\">title goes here</h1>\n</div></script>\n\n<div data-b=\"post\" data-c=\"bar\">\n  bar\n  <h1 data-b=\"title\">bar</h1>\n</div><script type=\"text/template\" data-b=\"post\" data-c=\"bar\"><div data-b=\"post\" data-c=\"bar\">\n  bar\n  <h1 data-b=\"title\">title goes here</h1>\n</div></script>\n\n  </body>\n</html>\n")
        end
      end

      context "exposure cannot be found" do
        let :app_definition do
          Proc.new {
            instance_exec(&$presenter_app_boilerplate)

            controller :default do
              get "/exposure" do
                expose :post, { title: "foo" }
                expose :nonexistent, {}
              end
            end
          }
        end

        it "does not fail" do
          expect(call("/exposure")[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    <div data-b=\"post\">\n  <h1 data-b=\"title\">foo</h1>\n</div><script type=\"text/template\" data-b=\"post\"><div data-b=\"post\">\n  <h1 data-b=\"title\">title goes here</h1>\n</div></script>\n\n  </body>\n</html>\n")
        end
      end
    end
  end

  context "view does not exist" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        controller :default do
          get "/nonexistent" do; end
        end
      }
    end

    it "renders a missing page error" do
      response = call("/nonexistent")
      expect(response[0]).to eq(404)
      expect(response[2].body.read).to include("Unknown page")
    end
  end

  context "route halts without rendering" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        controller :default do
          get "/other" do
            send "halted"
          end
        end
      }
    end

    it "does not automatically render the view" do
      response = call("/other")
      expect(response[0]).to eq(200)
      expect(response[2].body.read).to eq("halted")
    end
  end
end
