# frozen_string_literal: true

require "rack"

RSpec.describe Hanami::Action::Contract do
  describe "when defined as block in action" do
    let(:action) { ContractAction.new }
    it "is accessible as a Contract" do
      response = action.call("birth_date" => "2000-01-01")

      expect(response.status).to eq 302
      expect(response.body).to eq ["{:errors=>{:birth_date=>[\"is missing\"]}}"]
    end
  end

  describe "works as a standalone contract class" do
    it "validates the input" do
      contract = BaseContract.new(start_date: "2000-01-01")

      result = contract.call

      expect(result.errors.to_h).to eq(start_date: ["must be in the future"])
    end

    it "allows for usage of outside classes as schemas" do
      contract = OutsideSchemasContract.new(country: "PL", zipcode: "11-123", mobile: "123092902", name: "myguy")

      result = contract.call

      expect(result.errors.to_h).to eq(
        street: ["is missing"],
        email: ["is missing"],
        age: ["is missing"]
      )
    end
  end
end
