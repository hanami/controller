RSpec.describe Hanami::Controller::Configuration do
  let(:configuration) { Hanami::Controller::Configuration.new }

  describe 'handle exceptions' do
    it 'returns true by default' do
      expect(configuration.handle_exceptions).to be(true)
    end

    it 'allows to set the value with a writer' do
      configuration.handle_exceptions = false
      expect(configuration.handle_exceptions).to be(false)
    end
  end

  describe 'handled exceptions' do
    it 'returns an empty hash by default' do
      expect(configuration.handled_exceptions).to eq({})
    end

    it 'allows to set an exception' do
      configuration.handle_exception ArgumentError => 400
      expect(configuration.handled_exceptions).to include(ArgumentError)
    end
  end

  describe '#format' do
    before do
      configuration.format custom: 'custom/format'

      BaseObject = Class.new(BasicObject) do
        def hash
          23
        end
      end
    end

    after do
      Object.send(:remove_const, :BaseObject)
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
    before do
      configuration.format custom: 'custom/format'
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
      before do
        configuration.default_request_format = :html
      end

      it 'returns the value' do
        expect(configuration.default_request_format).to eq(:html)
      end
    end

    it 'raises an error if the given format cannot be coerced into symbol' do
      expect { configuration.default_request_format = 23 }.to raise_error(TypeError)
    end
  end

  describe '#default_response_format' do
    describe "when not previously set" do
      it 'returns nil' do
        expect(configuration.default_response_format).to be(nil)
      end
    end

    describe "when set" do
      before do
        configuration.default_response_format = :json
      end

      it 'returns the value' do
        expect(configuration.default_response_format).to eq(:json)
      end
    end

    it 'raises an error if the given format cannot be coerced into symbol' do
      expect { configuration.default_response_format = 23 }.to raise_error(TypeError)
    end
  end

  describe '#default_charset' do
    describe "when not previously set" do
      it 'returns nil' do
        expect(configuration.default_charset).to be(nil)
      end
    end

    describe "when set" do
      before do
        configuration.default_charset = 'latin1'
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
      before do
        configuration.format htm: 'text/html'
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
      before do
        configuration.format htm: 'text/html'
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

    describe "when set" do
      let(:headers) { { 'X-Frame-Options' => 'DENY' } }

      before do
        configuration.default_headers(headers)
      end

      it 'returns the value' do
        expect(configuration.default_headers).to eq(headers)
      end

      describe "multiple times" do
        before do
          configuration.default_headers(headers)
          configuration.default_headers('X-Foo' => 'BAR')
        end

        it 'returns the value' do
          expect(configuration.default_headers).to eq(
            'X-Frame-Options' => 'DENY',
            'X-Foo'           => 'BAR'
          )
        end
      end

      describe "with nil values" do
        before do
          configuration.default_headers(headers)
          configuration.default_headers('X-NIL' => nil)
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
      before do
        configuration.public_directory = 'static'
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
      before do
        configuration.public_directory = ::File.join(Dir.pwd, 'absolute')
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

  describe 'duplicate' do
    before do
      configuration.format custom: 'custom/format'
      configuration.default_request_format = :html
      configuration.default_response_format = :html
      configuration.default_charset = 'latin1'
      configuration.default_headers({ 'X-Frame-Options' => 'DENY' })
      configuration.public_directory = 'static'
    end

    let(:config) { configuration.duplicate }

    it 'returns a copy of the configuration' do
      expect(config.handle_exceptions).to       eq(configuration.handle_exceptions)
      expect(config.handled_exceptions).to      eq(configuration.handled_exceptions)
      expect(config.send(:formats)).to          eq(configuration.send(:formats))
      expect(config.mime_types).to              eq(configuration.mime_types)
      expect(config.default_request_format).to  eq(configuration.default_request_format)
      expect(config.default_response_format).to eq(configuration.default_response_format)
      expect(config.default_charset).to         eq(configuration.default_charset)
      expect(config.default_headers).to         eq(configuration.default_headers)
      expect(config.public_directory).to        eq(configuration.public_directory)
    end

    it "doesn't affect the original configuration" do
      config.handle_exceptions = false
      config.handle_exception ArgumentError => 400
      config.format another: 'another/format'
      config.default_request_format = :json
      config.default_response_format = :json
      config.default_charset = 'utf-8'
      config.default_headers({ 'X-Frame-Options' => 'ALLOW ALL' })
      config.public_directory = 'pub'

      expect(config.handle_exceptions).to            be(false)
      expect(config.handled_exceptions).to           eq(ArgumentError => 400)
      expect(config.format_for('another/format')).to eq(:another)
      expect(config.mime_types).to                   include('another/format')
      expect(config.default_request_format).to       eq(:json)
      expect(config.default_response_format).to      eq(:json)
      expect(config.default_charset).to              eq('utf-8')
      expect(config.default_headers).to              eq('X-Frame-Options' => 'ALLOW ALL')
      expect(config.public_directory).to             eq(::File.join(Dir.pwd, 'pub'))

      expect(configuration.handle_exceptions).to            be(true)
      expect(configuration.handled_exceptions).to           eq({})
      expect(configuration.format_for('another/format')).to be(nil)
      expect(configuration.mime_types).to_not               include('another/format')
      expect(configuration.default_request_format).to       eq(:html)
      expect(configuration.default_response_format).to      eq(:html)
      expect(configuration.default_charset).to              eq('latin1')
      expect(configuration.default_headers).to              eq('X-Frame-Options' => 'DENY')
      expect(configuration.public_directory).to             eq(::File.join(Dir.pwd, 'static'))
    end
  end
end
