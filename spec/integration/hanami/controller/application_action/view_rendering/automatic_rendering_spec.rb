require "hanami"

RSpec.describe "Application actions / View rendering / Automatic rendering", :application_integration do
  it "Renders a view automatically, passing all params and exposures" do
    within_app do
      write "slices/main/lib/main/actions/test.rb", <<~RUBY
        require "hanami/action"

        module Main
          module Actions
            class Test < Hanami::Action
              def handle(req, res)
                res[:favorite_number] = 123
                super
              end
            end
          end
        end
      RUBY

      write "slices/main/lib/main/views/test.rb", <<~RUBY
        module Main
          module Views
            class Test < Main::View
              expose :name, :favorite_number
            end
          end
        end
      RUBY

      write "slices/main/web/templates/test.html.slim", <<~'SLIM'
        h1 Hello, #{name}. Your favorite number is #{favorite_number}, right?
      SLIM

      require "hanami/init"

      action = Main::Slice["actions.test"]
      response = action.(name: "Jennifer")
      rendered = response.body[0]

      expect(rendered).to eq "<html><body><h1>Hello, Jennifer. Your favorite number is 123, right?</h1></body></html>"
      expect(response.status).to eq 200
    end
  end

  it "Does not render if no view is available" do
    within_app do
      write "slices/main/lib/main/actions/test.rb", <<~RUBY
        require "hanami/action"

        module Main
          module Actions
            class Test < Hanami::Action
            end
          end
        end
      RUBY

      require "hanami/init"

      action = Main::Slice["actions.test"]
      response = action.({})
      expect(response.body).to eq []
      expect(response.status).to eq 200
    end
  end

  def within_app
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "slices/main/lib/main/view.rb", <<~RUBY
        # auto_register: false

        require "hanami/view"

        module Main
          class View < Hanami::View
          end
        end
      RUBY

      write "slices/main/web/templates/layouts/application.html.slim", <<~SLIM
        html
          body
            == yield
      SLIM

      yield
    end
  end
end
