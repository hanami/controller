require "hanami"

RSpec.describe "Application actions / View rendering / Automatic rendering", :application_integration do
  it "Renders a view automatically, passing all params and exposures" do
    within_app do
      write "slices/main/actions/test.rb", <<~RUBY
        require "hanami/action"

        module Main
          module Actions
            class Test < Hanami::Action
              def handle(req, res)
                res[:favorite_number] = 123
              end
            end
          end
        end
      RUBY

      write "slices/main/views/test.rb", <<~RUBY
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

      require "hanami/prepare"

      action = Main::Slice["actions.test"]
      response = action.(name: "Jennifer")
      rendered = response.body[0]

      expect(rendered).to eq "<html><body><h1>Hello, Jennifer. Your favorite number is 123, right?</h1></body></html>"
      expect(response.status).to eq 200
    end
  end

  it "Does not render a view automatically when #render? returns false " do
    within_app do
      write "slices/main/actions/test.rb", <<~RUBY
        require "hanami/action"

        module Main
          module Actions
            class Test < Hanami::Action
              def handle(req, res)
                res[:favorite_number] = 123
              end

              def render?(_res)
                false
              end
            end
          end
        end
      RUBY

      write "slices/main/views/test.rb", <<~RUBY
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

      require "hanami/prepare"

      action = Main::Slice["actions.test"]
      response = action.(name: "Jennifer")

      expect(response.body).to eq []
      expect(response.status).to eq 200
    end
  end

  it "Doesn't render view automatically when body is already assigned" do
    within_app do
      write "slices/main/actions/test.rb", <<~RUBY
        require "hanami/action"

        module Main
          module Actions
            class Test < Hanami::Action
              def handle(req, res)
                res.body = "200: Okay okay okay"
              end
            end
          end
        end
      RUBY

      write "slices/main/views/test.rb", <<~RUBY
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

      require "hanami/prepare"

      action = Main::Slice["actions.test"]
      response = action.(name: "Jennifer")
      rendered = response.body[0]

      expect(rendered).to eq "200: Okay okay okay"
      expect(response.status).to eq 200
    end
  end

  it "Doesn't render view automatically when halt is called" do
    within_app do
      write "slices/main/actions/test.rb", <<~RUBY
        require "hanami/action"

        module Main
          module Actions
            class Test < Hanami::Action
              def handle(req, res)
                halt 404
              end
            end
          end
        end
      RUBY

      write "slices/main/views/test.rb", <<~RUBY
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

      require "hanami/prepare"

      action = Main::Slice["actions.test"]
      response = action.(name: "Jennifer")
      rendered = response.body[0]

      expect(rendered).to eq "Not Found"
      expect(response.status).to eq 404
    end
  end

  it "Does not render if no view is available" do
    within_app do
      write "slices/main/actions/test.rb", <<~RUBY
        require "hanami/action"

        module Main
          module Actions
            class Test < Hanami::Action
            end
          end
        end
      RUBY

      require "hanami/prepare"

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

      write "slices/main/lib/view.rb", <<~RUBY
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
