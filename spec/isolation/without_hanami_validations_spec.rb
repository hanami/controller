require_relative "../support/isolation_spec_helper"

RSpec.describe "Without validations" do
  it "doesn't load Hanami::Validations" do
    expect(defined?(Hanami::Validations)).to be(nil)
  end

  it "doesn't load Hanami::Action::Validatable" do
    expect(defined?(Hanami::Action::Validatable)).to be(nil)
  end

  it "doesn't load Hanami::Action::Params" do
    expect(defined?(Hanami::Action::Params)).to be(nil)
  end

  it "doesn't have params DSL" do
    expect do
      Class.new(Hanami::Action) do
        params do
          required(:id).filled
        end
      end
    end.to raise_error(
      NoMethodError,
      /To use `params`, please add 'hanami\/validations' gem to your Gemfile/
    )
  end

  it "has params that don't respond to .valid?" do
    action = Class.new(Hanami::Action) do
      def handle(req, res)
        res.body = [req.params.respond_to?(:valid?), req.params.valid?]
      end
    end

    response = action.new.call({})
    expect(response.body).to eq(["[true, true]"])
  end

  it "has params that don't respond to .errors" do
    action = Class.new(Hanami::Action) do
      def handle(req, res)
        res.body = req.params.respond_to?(:errors)
      end
    end

    response = action.new.call({})
    expect(response.body).to eq(["false"])
  end
end

RSpec::Support::Runner.run
