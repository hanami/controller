RSpec.describe Hanami::Action::BaseParams do
  let(:action) { Test::Index.new }

  describe "#initialize" do
    it "creates params without changing the raw request params" do
      env = {"router.params" => {"some" => {"hash" => "value"}}}
      action.call(env)
      expect(env["router.params"]).to eq("some" => {"hash" => "value"})
      expect(env["REQUEST_METHOD"]).to eq("GET")
    end
  end

  describe "#valid?" do
    it "always returns true" do
      response = action.call({})
      expect(response[:params]).to be_valid
    end
  end

  describe "#each" do
    it "iterates through params" do
      expected = {song: "Break The Habit"}
      params = described_class.new(expected.dup)
      actual = {}
      params.each do |key, value|
        actual[key] = value
      end

      expect(actual).to eq(expected)
    end
  end

  describe "#get" do
    let(:params) { described_class.new(delivery: {address: {city: "Rome"}}) }

    it "returns value if present" do
      expect(params.get(:delivery, :address, :city)).to eq("Rome")
    end

    it "returns nil if not present" do
      expect(params.get(:delivery, :address, :foo)).to be(nil)
    end

    it "is aliased as dig" do
      expect(params.dig(:delivery, :address, :city)).to eq("Rome")
    end
  end
end
