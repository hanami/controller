RSpec.describe Hanami::Controller do
  describe ".configuration" do
    it "exposes class configuration" do
      expect(Hanami::Controller.configuration).to be_kind_of(Hanami::Controller::Configuration)
    end
  end

  describe ".configure" do
    it "allows to configure the framework" do
      Hanami::Controller.class_eval do
        configure do |config|
          config.handle_exceptions = false
        end
      end

      expect(Hanami::Controller.configuration.handle_exceptions).to be(false)
    end

    it "allows to override one value" do
      Hanami::Controller.class_eval do
        configure do |config|
          config.handle_exception ArgumentError => 400
        end

        configure do |config|
          config.handle_exception NotImplementedError => 418
        end
      end

      expect(Hanami::Controller.configuration.handled_exceptions).to include(ArgumentError)
    end
  end
end
