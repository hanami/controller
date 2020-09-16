require "hanami/action/flash"

RSpec.describe Hanami::Action::Flash do
  let(:flash) { described_class.new(input_hash) }
  let(:input_hash) { {} }

  describe ".new" do
    context "nil given" do
      let(:input_hash) { nil }

      it "creates an empty hash" do
        expect(flash.now).to eq({})
        expect(flash.next).to eq({})
      end
    end

    context "existing hash given" do
      let(:input_hash) { {1 => 2} }

      it "assigns the hash as the now hash" do
        expect(flash.now).to eq(1=>2)
        expect(flash.next).to eq({})
      end
    end
  end

  describe "#now" do
    let(:input_hash) { { a: "val" } }

    it "returns raw data for the current request" do
      expect(flash.now).to be(input_hash)
    end

    it "is aliased as #to_h" do
      expect(flash.to_h).to be(input_hash)
    end
  end

  describe "#next" do
    it "returns raw data for the current request" do
      flash[:a] = "val"
      expect(flash.next).to eq(a: "val")
    end
  end

  describe "#[]" do
    let(:input_hash) { {a: "val"} }

    it "reads from the current request hash" do
      flash[:b] = "val2"

      expect(flash[:a]).to eq("val")
      expect(flash[:b]).to be(nil)
    end
  end

  describe "#[]=" do
    it "assigns to the next hash" do
      expect { flash[:a] = "val" }
        .to change { flash.next }
        .to(a: "val")
    end
  end

  describe "#each" do
    let(:input_hash) { {a: "val"} }

    it "iterates data" do
      accumulator = []

      flash.each do |k, v|
        accumulator << [k, v]
      end

      expect(accumulator).to eq(input_hash.to_a)
    end
  end

  describe "#map" do
    let(:input_hash) { {a: "val"} }

    it "iterates data and returns an Array" do
      accumulator = flash.map do |k, v|
        [k, v]
      end

      expect(accumulator).to eq(input_hash.to_a)
    end
  end

  describe "#empty?" do
    it "checks if current request data is empty" do
      expect(flash.empty?).to be(true)
    end
  end

  describe "#key?" do
    let(:input_hash) { {a: "val"} }

    it "checks if current request data has a value associated with the given key" do
      expect(flash.key?(:a)).to be(true)
      expect(flash.key?("a")).to be(false)
      expect(flash.key?(:b)).to be(false)
    end
  end

  describe "#discard" do
    context "key argument given" do
      before do
        flash[:a] = "a val"
        flash[:b] = "b val"
      end

      it "removes the given key from the next hash" do
        expect { flash.discard :a }
          .to change { flash.next }
          .from(a: "a val", b: "b val")
          .to(b: "b val")

        expect { flash.discard :b }
          .to change { flash.next }
          .to({})
      end
    end

    context "nil key argument given" do
      before do
        flash[:a] = "a val"
        flash[nil] = "nil val"
      end

      it "removes the given key from the next hash" do
        expect { flash.discard nil }
          .to change { flash.next }
          .from(a: "a val", nil => "nil val")
          .to(a: "a val")
      end
    end

    context "no argument given" do
      before do
        flash[:a] = "a val"
      end

      it "removes all entries from the next hash" do
        expect { flash.discard }
          .to change { flash.next }
          .from(a: "a val")
          .to({})
      end
    end
  end

  describe "#keep" do
    context "key argument given" do
      before do
        flash.now[:a] = "val"
      end

      it "copies entry for key from current hash to next hash" do
        expect { flash.keep(:a) }
          .to change { flash.next }
          .from({})
          .to(a: "val")
      end
    end

    context "nil key argument given" do
      before do
        flash.now[nil] = "val"
      end

      it "copies entry for key from current hash to next hash" do
        expect { flash.keep(nil) }
          .to change { flash.next }
          .from({})
          .to(nil => "val")
      end
    end

    context "no argument given" do
      before do
        flash.now[:a] = "val"
      end

      it "copies all entries from current hash to next hash" do
        expect { flash.keep }
          .to change { flash.next }
          .from({})
          .to(a: "val")
      end
    end
  end

  describe "#sweep" do
    before do
      flash[:a] = "val"
    end

    it "replaces the now hash with the next hash" do
      expect { flash.sweep }
        .to change { flash.next }.from(a: "val").to({})
        .and change { flash.now }.from({}).to(a: "val")
    end
  end
end
