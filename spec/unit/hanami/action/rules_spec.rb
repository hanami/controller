# frozen_string_literal: true

require "rack"

RSpec.describe Hanami::Action do
  # Deprecated behavior
  describe ".params" do
    let(:klass) do
      Class.new(described_class) do
        puts "Defining params"
        params do
          required(:book).schema do
            required(:code).filled(:str?)
          end
        end

        def handle(request, response)
          response[:params] = request.params
        end
      end
    end

    let(:action) { klass.new() }
    let(:response) { action.call(given_input) }

    context "given valid input" do
      let(:given_input) { { book: { code: "abc" } } }

      it "is valid" do
        expect(response[:params].valid?).to eq(true)
      end
    end

    context "given invalid input" do
      let(:given_input) { { book: { code: nil } } }

      it "is not valid" do
        expect(response[:params].valid?).to eq(false)
      end
    end
  end

  describe ".contract" do
    
    context "when providing a block" do
      let(:klass) do
        Class.new(described_class) do
          contract do
            params do
              required(:book).schema do
                required(:code).filled(:str?)
              end
            end
            rule("book.code") do
                key.failure('must be "abc"') unless value == "abc"
            end
          end
  
          def handle(request, response)
            response[:params] = request.params
          end
        end
      end

      let(:action) { klass.new() }
      let(:response) { action.call(given_input) }

      context "given valid input" do
        let(:given_input) { { book: { code: "abc" } } }

        it "is valid" do
          expect(response[:params].valid?).to eq(true)
        end
      end

      context "given invalid input" do
        let(:given_input) { { book: { code: nil } } }

        it "is not valid" do
          expect(response[:params].valid?).to eq(false)
        end
      end

      context "given input which does not pass rules" do
        let(:given_input) { { book: { code: "xyz" } } }

        it "is not valid" do
          expect(response[:params].valid?).to eq(false)
        end
      end
    end
  end
end
