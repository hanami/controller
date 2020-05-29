# frozen_string_literal: true

require "hanami"
require "hanami/action"
require "hanami/view"
require "slim"

RSpec.describe "View rendering in application actions", :application_integration do
  specify "Views render with a request-specific context object" do
    with_tmp_directory(Dir.mktmpdir) do
      write "config/application.rb", <<~RUBY
        require "hanami"

        module TestApp
          class Application < Hanami::Application
          end
        end
      RUBY

      write "slices/main/lib/main/action.rb", <<~RUBY
        # auto_register: false

        module Main
          class Action < Hanami::Action
          end
        end
      RUBY

      write "slices/main/lib/main/actions/test_action.rb", <<~RUBY
        require "main/action"

        module Main
          module Actions
            class TestAction < Main::Action
              include Deps[view: "views.test_view"]

              def handle(req, res)
                res.render view, name: req.params[:name]
              end
            end
          end
        end
      RUBY

      write "slices/main/lib/main/view/context.rb", <<~RUBY
        module Main
          class View < Hanami::View
            class Context < Hanami::View::Context
              def request
                _options.fetch(:request)
              end

              def response
                _options.fetch(:response)
              end
            end
          end
        end
      RUBY

      write "slices/main/lib/main/view.rb", <<~RUBY
        # auto_register: false

        module Main
          class View < Hanami::View
          end
        end
      RUBY

      write "slices/main/lib/main/views/test_view.rb", <<~RUBY
        require "main/view"

        module Main
          module Views
            class TestView < Main::View
              expose :name
            end
          end
        end
      RUBY

      write "slices/main/web/templates/layouts/application.html.slim", <<~SLIM
        html
          body
            == yield
      SLIM

      write "slices/main/web/templates/test_view.html.slim", <<~'SLIM'
        h1 Hello, #{name}
        - request.params.to_h.values.sort.each do |value|
          p = value
      SLIM

      require "hanami/init"

      action = Main::Slice["actions.test_action"]
      response = action.(name: "Jennifer", last_name: "Lopez")
      rendered = response.body[0]

      expect(rendered).to eq "<html><body><h1>Hello, Jennifer</h1><p>Jennifer</p><p>Lopez</p></body></html>"
    end
  end
end
