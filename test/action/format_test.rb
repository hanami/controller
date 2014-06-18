require 'test_helper'

describe Lotus::Action do
  class FormatController
    include Lotus::Controller

    action 'Default' do
      def call(params)
      end
    end

    action 'Custom' do
      def call(params)
        self.format = params[:format]
      end
    end
  end

  before do
    @mime   = ::Rack::Mime::MIME_TYPES
  end

  describe '#format' do
    before do
      @action = FormatController::Default.new
    end

    it 'lookup to #content_type if was not explicitly set (default: application/octet-stream)' do
      @action.call({})
      @action.send(:format).must_equal :all
    end
  end

  describe '#format=' do
    before do
      @action = FormatController::Custom.new
    end

    describe 'html' do
      before do
        @action.call({ format: :html })
      end

      it 'sets format' do
        @action.send(:format).must_equal :html
      end

      it 'sets content-type' do
        @action.send(:content_type).must_equal 'text/html'
      end
    end

    describe 'json' do
      before do
        @action.call({ format: :json })
      end

      it 'sets format' do
        @action.send(:format).must_equal :json
      end

      it 'sets content-type' do
        @action.send(:content_type).must_equal 'application/json'
      end
    end

    describe 'xml' do
      before do
        @action.call({ format: :xml })
      end

      it 'sets format' do
        @action.send(:format).must_equal :xml
      end

      it 'sets content-type' do
        @action.send(:content_type).must_equal 'application/xml'
      end
    end

    describe 'atom' do
      before do
        @action.call({ format: :atom })
      end

      it 'sets format' do
        @action.send(:format).must_equal :atom
      end

      it 'sets content-type' do
        @action.send(:content_type).must_equal 'application/atom+xml'
      end
    end

    describe 'js' do
      before do
        @action.call({ format: :js })
      end

      it 'sets format' do
        @action.send(:format).must_equal :js
      end

      it 'sets content-type' do
        @action.send(:content_type).must_equal 'application/javascript'
      end
    end
  end
end
