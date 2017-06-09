RSpec.describe Hanami::Controller::Configuration do
  let(:configuration) { described_class.new }

  describe "#initialize" do
    it "returns a frozen instance" do
      expect(configuration).to be_frozen
    end
  end

  describe 'handle exceptions' do
    it 'returns true by default' do
      expect(configuration.handle_exceptions).to be(true)
    end

    it 'allows to set the value with a writer' do
      configuration = described_class.new do |config|
        config.handle_exceptions = false
      end

      expect(configuration.handle_exceptions).to be(false)
    end
  end

  describe 'handled exceptions' do
    it 'returns an empty hash by default' do
      expect(configuration.handled_exceptions).to eq({})
    end

    it 'allows to set an exception' do
      configuration = described_class.new do |config|
        config.handle_exception ArgumentError => 400
      end

      expect(configuration.handled_exceptions).to include(ArgumentError)
    end
  end

  describe '#format' do
    before do
      BaseObject = Class.new(BasicObject) do
        def hash
          23
        end
      end
    end

    after do
      Object.send(:remove_const, :BaseObject)
    end

    let(:configuration) do
      described_class.new do |config|
        config.format custom: 'custom/format'
      end
    end

    it 'registers the given format' do
      expect(configuration.format_for('custom/format')).to eq(:custom)
    end

    it 'raises an error if the given format cannot be coerced into symbol' do
      expect { configuration.format(23 => 'boom') }.to raise_error(TypeError)
    end

    it 'raises an error if the given mime type cannot be coerced into string' do
      expect { configuration.format(boom: BaseObject.new) }.to raise_error(TypeError)
    end
  end

  describe '#mime_types' do
    let(:configuration) do
      described_class.new do |config|
        config.format custom: 'custom/format'
      end
    end

    it 'returns all known MIME types' do
      all = ["custom/format"]
      expect(configuration.mime_types).to eq(all + Hanami::Action::Mime::MIME_TYPES.values)
    end

    it 'returns correct values even after the value is cached' do
      configuration.mime_types
      configuration.format electroneering: 'custom/electroneering'

      all = ["custom/format", "custom/electroneering"]
      expect(configuration.mime_types).to eq(all + Hanami::Action::Mime::MIME_TYPES.values)
    end
  end

  describe '#default_request_format' do
    describe "when not previously set" do
      it 'returns nil' do
        expect(configuration.default_request_format).to be(nil)
      end
    end

    describe "when set" do
      let(:configuration) do
        described_class.new do |config|
          config.default_request_format = :html
        end
      end

      it 'returns the value' do
        expect(configuration.default_request_format).to eq(:html)
      end
    end

    it 'raises an error if the given format cannot be coerced into symbol' do
      expect do
        described_class.new do |config|
          config.default_request_format = 23
        end
      end.to raise_error(TypeError)
    end
  end

  describe '#default_response_format' do
    describe "when not previously set" do
      it 'returns nil' do
        expect(configuration.default_response_format).to be(nil)
      end
    end

    describe "when set" do
      let(:configuration) do
        described_class.new do |config|
          config.default_response_format = :json
        end
      end

      it 'returns the value' do
        expect(configuration.default_response_format).to eq(:json)
      end
    end

    it 'raises an error if the given format cannot be coerced into symbol' do
      expect do
        described_class.new do |config|
          config.default_response_format = 23
        end
      end.to raise_error(TypeError)
    end
  end

  describe '#default_charset' do
    describe "when not previously set" do
      it 'returns nil' do
        expect(configuration.default_charset).to be(nil)
      end
    end

    describe "when set" do
      let(:configuration) do
        described_class.new do |config|
          config.default_charset = 'latin1'
        end
      end

      it 'returns the value' do
        expect(configuration.default_charset).to eq('latin1')
      end
    end
  end

  describe '#format_for' do
    it 'returns a symbol from the given mime type' do
      expect(configuration.format_for('*/*')).to                      eq(:all)
      expect(configuration.format_for('application/octet-stream')).to eq(:all)
      expect(configuration.format_for('text/html')).to                eq(:html)
    end

    describe 'with custom defined formats' do
      let(:configuration) do
        described_class.new do |config|
          config.format htm: 'text/html'
        end
      end

      it 'returns the custom defined mime type, which takes the precedence over the builtin value' do
        expect(configuration.format_for('text/html')).to eq(:htm)
      end
    end
  end

  describe '#mime_type_for' do
    it 'returns a mime type from the given symbol' do
      expect(configuration.mime_type_for(:all)).to  eq('application/octet-stream')
      expect(configuration.mime_type_for(:html)).to eq('text/html')
    end

    describe 'with custom defined formats' do
      let(:configuration) do
        described_class.new do |config|
          config.format htm: 'text/html'
        end
      end

      it 'returns the custom defined format, which takes the precedence over the builtin value' do
        expect(configuration.mime_type_for(:htm)).to eq('text/html')
      end
    end
  end

  describe '#default_headers' do
    describe "when not previously set" do
      it 'returns default value' do
        expect(configuration.default_headers).to eq({})
      end
    end

    context "when set" do
      let(:configuration) do
        h = headers
        described_class.new do |config|
          config.default_headers(h)
        end
      end

      let(:headers) { { 'X-Frame-Options' => 'DENY' } }

      it 'returns the value' do
        expect(configuration.default_headers).to eq(headers)
      end

      context "with nil values" do
        let(:configuration) do
          h = headers
          described_class.new do |config|
            config.default_headers(h.merge('X-NIL' => nil))
          end
        end

        it 'rejects those' do
          expect(configuration.default_headers).to eq(headers)
        end
      end
    end
  end

  describe "#public_directory" do
    describe "when not previously set" do
      it "returns default value" do
        expected = ::File.join(Dir.pwd, 'public')
        actual   = configuration.public_directory

        # NOTE: For Rack compatibility it's important to have a string as public directory
        expect(actual).to be_kind_of(String)
        expect(actual).to eq(expected)
      end
    end

    describe "when set with relative path" do
      let(:configuration) do
        described_class.new do |config|
          config.public_directory = 'static'
        end
      end

      it "returns the value" do
        expected = ::File.join(Dir.pwd, 'static')
        actual   = configuration.public_directory

        # NOTE: For Rack compatibility it's important to have a string as public directory
        expect(actual).to be_kind_of(String)
        expect(actual).to eq(expected)
      end
    end

    describe "when set with absolute path" do
      let(:configuration) do
        described_class.new do |config|
          config.public_directory = ::File.join(Dir.pwd, 'absolute')
        end
      end

      it "returns the value" do
        expected = ::File.join(Dir.pwd, 'absolute')
        actual   = configuration.public_directory

        # NOTE: For Rack compatibility it's important to have a string as public directory
        expect(actual).to be_kind_of(String)
        expect(actual).to eq(expected)
      end
    end
  end
end
