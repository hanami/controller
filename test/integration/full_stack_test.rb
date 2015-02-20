require 'test_helper'
require 'rack/test'

describe 'Full stack application' do
  include Rack::Test::Methods

  def app
    FullStack::Application.new
  end

  it 'passes action inside the Rack env' do
    get '/', {}, 'HTTP_ACCEPT' => 'text/html'

    last_response.body.must_include 'FullStack::Controllers::Home::Index'
    last_response.body.must_include ':greeting=>"Hello"'
    last_response.body.must_include ':format=>:html'
  end

  it 'omits the body if the request is HEAD' do
    head '/head', {}, 'HTTP_ACCEPT' => 'text/html'

    last_response.body.must_be_empty
    last_response.headers['X-Renderable'].must_be_nil
  end

  it 'in case of redirect and invalid params, it passes errors in session and then deletes them' do
    post '/books', { title: '' }
    follow_redirect!

    last_response.body.must_include 'FullStack::Controllers::Books::Index'
    last_response.body.must_include %(@actual="")

    get '/books'
    last_response.body.wont_include %(@actual="")
  end

  it 'uses flash to pass informations' do
    get '/poll'
    follow_redirect!

    last_response.body.must_include 'FullStack::Controllers::Poll::Step1'
    last_response.body.must_include %(Start the poll)

    # post '/poll/1', {}
    # follow_redirect!

    # last_response.body.must_include 'FullStack::Controllers::Poll::Step2'
    # last_response.body.must_include %(Step 1 completed)
  end

  it 'can access params with string symbols or methods' do
    patch '/books/1', {
      id: '1',
      book: {
        title: 'Lotus in Action',
        author: {
          name: 'Luca'
        }
      }
    }
    result = Marshal.load(last_response.body)
    result.must_equal({
      method_access: 'Luca',
      symbol_access: 'Luca',
      string_access: 'Luca',
      valid: true,
      errors: {}
    })
  end

  it 'validates nested params' do
    patch '/books/1', {
      id: '1',
      book: {
        title: 'Lotus in Action',
      }
    }
    result = Marshal.load(last_response.body)
    result[:valid].must_equal false
    result[:errors].must_equal({
      'book.author.name' => [Lotus::Validations::Error.new('book.author.name', :presence, true, nil)]
    })
  end
end
