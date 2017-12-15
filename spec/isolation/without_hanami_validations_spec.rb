require_relative '../support/isolation_spec_helper'

RSpec.describe 'Without validations' do
  let(:configuration) do
    Hanami::Controller::Configuration.new
  end

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
    end.to raise_error(NoMethodError, /undefined method `params' for/)
  end

  it "has params that don't respond to .valid?" do
    action = Class.new(Hanami::Action) do
      def call(req, res)
        res.body = [req.params.respond_to?(:valid?), req.params.valid?]
      end
    end

    response = action.new(configuration: configuration).call({})
    expect(response.body).to eq(["[true, true]"])
  end

  it "has params that don't respond to .errors" do
    action = Class.new(Hanami::Action) do
      def call(req, res)
        res.body = req.params.respond_to?(:errors)
      end
    end

    response = action.new(configuration: configuration).call({})
    expect(response.body).to eq(["false"])
  end
end

RSpec::Support::Runner.run
