RSpec.describe Hanami::Action::Configuration do
  subject(:configuration) { described_class.new }

  describe '#handled_exceptions' do
    it 'is an empty hash by default' do
      expect(configuration.handled_exceptions).to eq({})
    end

    it 'allows specifying a complete set of exceptions' do
      configuration.handled_exceptions = {ArgumentError => 400}
      expect(configuration.handled_exceptions).to eq(ArgumentError => 400)
    end

    it 'allows adding individual exceptions' do
      configuration.handle_exception ArgumentError => 400
      expect(configuration.handled_exceptions).to eq(ArgumentError => 400)

      configuration.handle_exception TypeError => 400
      expect(configuration.handled_exceptions).to eq(ArgumentError => 400, TypeError => 400)
    end
  end

  describe '#formats' do
    it 'is a basic set of mime type to format mappings by default' do
      expect(configuration.formats).to eq(
        'application/octet-stream' => :all,
        '*/*' => :all,
        'text/html' => :html
      )
    end

    it 'can be set with a new mime type to format mappings' do
      configuration.formats = {'*/*' => :all}
      expect(configuration.formats).to eq('*/*' => :all)
    end
  end

  describe '#format' do
    before do
      configuration.formats = {'text/html' => :html}
    end

    it 'adds the given MIME type to format mapping' do
      configuration.format custom: 'custom/format'

      expect(configuration.formats).to eq(
        'text/html' => :html,
        'custom/format' => :custom
      )
    end

    it 'replaces the mapping for an existing MIME type' do
      configuration.format custom: 'text/html'

      expect(configuration.formats).to eq('text/html' => :custom)
    end

    it 'raises an error if the given format cannot be coerced into symbol' do
      expect { configuration.format(23 => 'boom') }.to raise_error(TypeError)
    end

    it 'raises an error if the given mime type cannot be coerced into string' do
      obj = Class.new(BasicObject) do
        def hash
          23
        end
      end.new

      expect { configuration.format(boom: obj) }.to raise_error(TypeError)
    end
  end

  describe '#format_for' do
    before do
      configuration.formats = {'text/html' => :html}
    end

    it 'returns the configured format for the given MIME type' do
      expect(configuration.format_for('text/html')).to eq :html
    end

    it 'returns the most recently configured format for a given MIME type' do
      configuration.format htm: 'text/html'

      expect(configuration.format_for('text/html')).to eq(:htm)
    end

    it 'returns nil if no matching format is found' do
      expect(configuration.format_for('*/*')).to be nil
    end
  end

  describe '#mime_types' do
    it 'returns the MIME types from the configured formats (as well as the default MIME types)' do
      configuration.formats = {'custom/type' => :custom}
      expect(configuration.mime_types).to eq ['custom/type'] + Hanami::Action::Mime::TYPES.values
    end
  end

  describe '#mime_type_for' do
    before do
      configuration.formats = {'text/html' => :html}
    end

    it 'returns the configured MIME type for the given format' do
      expect(configuration.mime_type_for(:html)).to eq 'text/html'
    end

    it 'returns nil if no matching MIME type is found' do
      expect(configuration.mime_type_for(:missing)).to be nil
    end
  end

  describe '#default_request_format' do
    it 'is nil by default' do
      expect(configuration.default_request_format).to be nil
    end

    it 'can be set with a format symbol' do
      configuration.default_request_format = :html
      expect(configuration.default_request_format).to eq(:html)
    end

    it 'raises an error if the given format cannot be coerced into symbol' do
      expect {
        configuration.default_request_format = 23
      }.to raise_error(TypeError)
    end
  end

  describe '#default_response_format' do
    it 'is nil by default' do
      expect(configuration.default_response_format).to be nil
    end

    it 'can be set with a format symbol' do
      configuration.default_response_format = :json
      expect(configuration.default_response_format).to eq(:json)
    end

    it 'raises an error if the given format cannot be coerced into symbol' do
      expect {
        configuration.default_response_format = 23
      }.to raise_error(TypeError)
    end
  end

  describe '#default_charset' do
    it 'is nil by default' do
      expect(configuration.default_charset).to be nil
    end

    it 'can be set with a charset string' do
      configuration.default_charset = 'latin1'
      expect(configuration.default_charset).to eq('latin1')
    end
  end

  describe '#default_headers' do
    it 'is an empty hash by default' do
      expect(configuration.default_headers).to eq({})
    end

    it 'can be set with a headers hash' do
      configuration.default_headers = {'X-Frame-Options' => 'DENY'}
      expect(configuration.default_headers).to eq('X-Frame-Options' => 'DENY')
    end

    it 'rejects headers with nil values' do
      configuration.default_headers = {'X-Nil' => nil}
      expect(configuration.default_headers).to eq({})
    end
  end

  describe '#cookies' do
    it 'is an empty hash by default' do
      expect(configuration.cookies).to eq({})
    end

    it 'can be set with a cookie configuration hash' do
      configuration.cookies = {domain: 'hanamirb.org', secure: true}
      expect(configuration.cookies).to eq(domain: 'hanamirb.org', secure: true)
    end

    it 'rejects nil values' do
      configuration.cookies = {domain: nil}
      expect(configuration.cookies).to eq({})
    end
  end

  describe "#root_directory" do
    it "is the current working directory by default" do
      expect(configuration.root_directory).to be_a Pathname
      expect(configuration.root_directory.to_s).to eq Dir.pwd
    end

    it "can be set with another directory" do
      configuration.root_directory = __dir__

      expect(configuration.root_directory).to be_a Pathname
      expect(configuration.root_directory.to_s).to eq __dir__
    end

    it "raises an error when set with a non-existent directory" do
      expect {
        configuration.root_directory = "/non-existent"
      }.to raise_error(StandardError)
    end
  end

  describe "public_directory" do
    let(:root_directory) { __dir__ }

    before do
      configuration.root_directory = __dir__
    end

    it "returns the public/ within the root directory by default" do
      expect(configuration.public_directory).to eql(File.join(root_directory, "public"))
    end

    it "can be set with a relative path" do
      configuration.public_directory = 'static'
      expect(configuration.public_directory).to eql(File.join(root_directory, "static"))
    end

    it "can be set with an abolute path" do
      configuration.public_directory = File.join(__dir__, 'absolute')
      expect(configuration.public_directory).to eql(File.join(root_directory, "absolute"))
    end
  end
end
