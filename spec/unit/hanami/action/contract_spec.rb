# frozen_string_literal: true

require "rack"

RSpec.describe Hanami::Action::Contract do
  describe "when defined as block in action" do
    let(:action) { ContractAction.new }
    context "when it has errors" do
      it "returns them" do
        response = action.call("birth_date" => "2000-01-01")

        expect(response.status).to eq 302
        expect(response.body).to eq ["{:errors=>{:book=>[\"is missing\"], :birth_date=>[\"you must be 18 years or older\"]}}"]
      end
    end

    context "when it is valid" do
      it "works" do
        response = action.call("birth_date" => Date.today - (365 * 15), "book" => {"title" => "Hanami"})

        expect(response.status).to eq 201
        expect(response.body).to eq ["{\"new_name\":\"HANAMI\"}"]
      end
    end
  end

  describe "works as a standalone contract class" do
    it "validates the input" do
      contract = BaseContract.new(start_date: "2000-01-01")

      expect(contract.errors.to_h).to eq(start_date: ["must be in the future"])
    end

    it "allows for usage of outside classes as schemas" do
      contract = OutsideSchemasContract.new(country: "PL", zipcode: "11-123", mobile: "123092902", name: "myguy")

      expect(contract.errors.to_h).to eq(
        street: ["is missing"],
        email: ["is missing"],
        age: ["is missing"]
      )
    end
  end
end
