# frozen_string_literal: true

RSpec.describe Hanami::Action::Halt do
  it "throws :halt with an integer status code" do
    expect { described_class.(401) }.to throw_symbol(:halt, [401, "Unauthorized"])
  end

  it "normalizes a symbolic status code" do
    expect { described_class.(:unauthorized) }.to throw_symbol(:halt, [401, "Unauthorized"])
  end
end
