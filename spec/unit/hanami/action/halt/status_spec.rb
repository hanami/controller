RSpec.describe Hanami::Action::Halt do
  it "throws :halt with an integer status code" do
    expect { described_class.(401) }.to throw_symbol(:halt, [401, "Unauthorized"])
  end

  it "normalizes a symbolic status code" do
    expect { described_class.(:unauthorized) }.to throw_symbol(:halt, [401, "Unauthorized"])
  end

  it "raises error with an unknown integer status code" do
    expect { described_class.(999) }.to raise_exception(Hanami::Action::UnknownHttpStatusError, /unknown HTTP status: `999'/)
  end

  it "raises error with an unknown symbol status code" do
    expect { described_class.(:foo) }.to raise_exception(Hanami::Action::UnknownHttpStatusError, /unknown HTTP status: `:foo'/)
  end
end
