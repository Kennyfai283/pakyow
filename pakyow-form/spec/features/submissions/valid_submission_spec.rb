RSpec.describe "submitting valid form data" do
  include_context "testable app"

  let :app_definition do
    Proc.new do
      instance_exec(&$form_app_boilerplate)

      resource :post, "/posts" do
        disable_protection :csrf

        new do; end

        create do
          verify do
            required :post do
              required :title
            end
          end

          res.body << "created #{params[:post][:title]}"
        end
      end
    end
  end

  it "calls the route in a normal way" do
    call("/posts", method: :post, params: { post: { title: "foo" } }).tap do |result|
      expect(result[0]).to be(200)
      expect(result[2].body.join).to eq("created foo")
    end
  end
end
