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

  describe "#raw" do
    let(:params) { Class.new(Hanami::Action::Contract) }

    context "when this feature isn't enabled" do
      let(:action) { RawContractAction.new }

      it "raw gets all params" do
        File.open("spec/support/fixtures/multipart-upload.png", "rb") do |upload|
          response = action.call("id" => "1", "unknown" => "2", "upload" => upload)

          expect(response[:params][:id]).to eq("1")
          expect(response[:params][:unknown]).to eq("2")
          expect(FileUtils.cmp(response[:params][:upload], upload)).to be(true)

          expect(response[:params].raw.fetch("id")).to eq("1")
          expect(response[:params].raw.fetch("unknown")).to eq("2")
          expect(response[:params].raw.fetch("upload")).to eq(upload)
        end
      end
    end

    context "when this feature is enabled" do
      let(:action) { WhitelistedUploadDslContractAction.new }

      it "raw gets all params" do
        Tempfile.create("multipart-upload") do |upload|
          response = action.call("id" => "1", "unknown" => "2", "upload" => upload, "_csrf_token" => "3")

          expect(response[:params][:id]).to          eq(1)
          expect(response[:params][:unknown]).to     be(nil)
          expect(response[:params][:upload]).to      eq(upload)

          expect(response[:params].raw.fetch("id")).to          eq("1")
          expect(response[:params].raw.fetch("unknown")).to     eq("2")
          expect(response[:params].raw.fetch("upload")).to      eq(upload)
        end
      end
    end
  end

  describe "validations" do
    it "isn't valid with empty params" do
      params = TestContract.new({})

      expect(params.valid?).to be(false)

      expect(params.errors.fetch(:email)).to   eq(["is missing"])
      expect(params.errors.fetch(:name)).to    eq(["is missing"])
      expect(params.errors.fetch(:tos)).to     eq(["is missing"])
      expect(params.errors.fetch(:address)).to eq(["is missing"])

      expect(params.error_messages).to eq(["Name is missing", "Email is missing", "Tos is missing", "Age is missing", "Address is missing"])
    end

    it "isn't valid with empty nested params" do
      params = NestedContractParams.new(signup: {})

      expect(params.valid?).to be(false)

      expect(params.errors.fetch(:signup).fetch(:name)).to eq(["is missing"])

      with_hanami_validations(1) do
        expect(params.error_messages).to eq(["Name is missing", "Age is missing", "Age must be greater than or equal to 18"])
      end

      with_hanami_validations(2) do
        expect(params.error_messages).to eq(["Name is missing", "Age is missing"])
      end
    end

    it "is it valid when all the validation criteria are met" do
      params = TestContract.new(email: "test@hanamirb.org",
                                password: "123456",
                                password_confirmation: "123456",
                                name: "Luca",
                                tos: true,
                                age: 34,
                                address: {
                                  line_one: "10 High Street",
                                  deep: {
                                    deep_attr: "blue"
                                  }
                                })

      expect(params.valid?).to         be(true)
      expect(params.errors).to         be_empty
      expect(params.error_messages).to be_empty
    end

    it "has input available through the hash accessor" do
      params = TestContract.new(name: "John", age: "1", address: {line_one: "10 High Street"})

      expect(params[:name]).to               eq("John")
      expect(params[:age]).to                be("1")
      expect(params[:address][:line_one]).to eq("10 High Street")
    end

    it "allows nested hash access via symbols" do
      params = TestContract.new(name: "John", address: {line_one: "10 High Street", deep: {deep_attr: 1}})
      expect(params[:name]).to                       eq("John")
      expect(params[:address][:line_one]).to         eq("10 High Street")
      expect(params[:address][:deep][:deep_attr]).to be(1)
    end
  end

  describe "#get" do
    context "with data" do
      let(:params) do
        TestContract.new(
          name: "Luca",
          address: {line_one: "10 High Street", deep: {deep_attr: 1}},
          array: [{name: "Lennon"}, {name: "Wayne"}]
        )
      end

      it "returns nil for nil argument" do
        expect(params.get(nil)).to be(nil)
      end

      it "returns nil for unknown param" do
        expect(params.get(:unknown)).to be(nil)
      end

      it "allows to read top level param" do
        expect(params.get(:name)).to eq("Luca")
      end

      it "allows to read nested param" do
        expect(params.get(:address, :line_one)).to eq("10 High Street")
      end

      it "returns nil for unknown nested param" do
        expect(params.get(:address, :unknown)).to be(nil)
      end

      it "allows to read data under arrays" do
        expect(params.get(:array, 0, :name)).to eq("Lennon")
        expect(params.get(:array, 1, :name)).to eq("Wayne")
      end
    end

    context "without data" do
      let(:params) { TestContract.new({}) }

      it "returns nil for nil argument" do
        expect(params.get(nil)).to be(nil)
      end

      it "returns nil for unknown param" do
        expect(params.get(:unknown)).to be(nil)
      end

      it "returns nil for top level param" do
        expect(params.get(:name)).to be(nil)
      end

      it "returns nil for nested param" do
        expect(params.get(:address, :line_one)).to be(nil)
      end

      it "returns nil for unknown nested param" do
        expect(params.get(:address, :unknown)).to be(nil)
      end
    end
  end

  context "without data" do
    let(:params) { TestContract.new({}) }

    it "returns nil for nil argument" do
      expect(params.get(nil)).to be(nil)
    end

    it "returns nil for unknown param" do
      expect(params.get(:unknown)).to be(nil)
    end

    it "returns nil for top level param" do
      expect(params.get(:name)).to be(nil)
    end

    it "returns nil for nested param" do
      expect(params.get(:address, :line_one)).to be(nil)
    end

    it "returns nil for unknown nested param" do
      expect(params.get(:address, :unknown)).to be(nil)
    end
  end

  describe "#deconstruct_keys" do
    it "supports pattern-matching" do
      contract = TestContract.new(name: "Luca")
      contract => { name: }
      expect(name).to eq("Luca")
    end
  end

  describe "#to_h" do
    let(:params) { TestContract.new(name: "Luca") }

    it "returns a ::Hash" do
      expect(params.to_hash).to be_kind_of(::Hash)
    end

    it "returns unfrozen Hash" do
      expect(params.to_hash).to_not be_frozen
    end

    it "handles nested params" do
      input = {
        "address" => {
          "deep" => {
            "deep_attr" => "foo"
          }
        }
      }

      expected = {
        address: {
          deep: {
            deep_attr: "foo"
          }
        }
      }

      actual = TestContract.new(input).to_hash
      expect(actual).to eq(expected)

      expect(actual).to                  be_kind_of(::Hash)
      expect(actual[:address]).to        be_kind_of(::Hash)
      expect(actual[:address][:deep]).to be_kind_of(::Hash)
    end
  end

  describe "#to_hash" do
    let(:params) { TestContract.new(name: "Luca") }

    it "returns a ::Hash" do
      expect(params.to_hash).to be_kind_of(::Hash)
    end

    it "returns unfrozen Hash" do
      expect(params.to_hash).to_not be_frozen
    end

    it "handles nested params" do
      input = {
        "address" => {
          "deep" => {
            "deep_attr" => "foo"
          }
        }
      }

      expected = {
        address: {
          deep: {
            deep_attr: "foo"
          }
        }
      }

      actual = TestContract.new(input).to_hash
      expect(actual).to eq(expected)

      expect(actual).to                  be_kind_of(::Hash)
      expect(actual[:address]).to        be_kind_of(::Hash)
      expect(actual[:address][:deep]).to be_kind_of(::Hash)
    end
  end

  describe "#errors" do
    let(:klass) do
      Class.new(described_class) do
        contract do
          params do
            required(:birth_date).filled(:date)
          end

          rule(:birth_date) do
            key.failure("you must be 18 years or older") if value < Date.today << (12 * 18)
          end
        end
      end
    end

    let(:params) { klass.new(birth_date: Date.today) }

    it "is of type Hanami::Action::Params::Errors" do
      expect(params.errors).to be_kind_of(Hanami::Action::Params::Errors)
    end

    it "affects #valid?" do
      expect(params).to be_valid

      params.errors.add(:birth_date, "is not unique")
      expect(params).to_not be_valid
    end

    it "appends message to already existing messages" do
      params = klass.new(birth_date: "")
      params.errors.add(:birth_date, "is invalid")

      expect(params.error_messages).to eq(["Birth Date must be filled", "Birth Date is invalid"])
    end

    it "is included in #error_messages" do
      params.errors.add(:birth_date, "is not unique")
      expect(params.error_messages).to eq(["Birth Date is not unique"])
    end
  end
end
