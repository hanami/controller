require 'test_helper'
require 'hanami/router'

Routes = Hanami::Router.new do
  get '/',         to: 'root'
  get '/team',     to: 'about#team'
  get '/contacts', to: 'about#contacts'

  resource  :identity
  resources :flowers
  resources :painters, only: [:update]
end

describe 'Hanami::Router integration' do
  before do
    @app = Rack::MockRequest.new(Routes)
  end

  it 'calls simple action' do
    response = @app.get('/')

    response.status.must_equal 200
    response.body.must_equal '{}'
    response.headers['X-Test'].must_equal 'test'
  end

  it "calls a controller's class action" do
    response = @app.get('/team')

    response.status.must_equal 200
    response.body.must_equal '{}'
    response.headers['X-Test'].must_equal 'test'
  end

  it "calls a controller's action (with DSL)" do
    response = @app.get('/contacts')

    response.status.must_equal 200
    response.body.must_equal '{}'
  end

  it 'returns a 404 for unknown path' do
    response = @app.get('/unknown')

    response.status.must_equal 404
  end

  describe 'resource' do
    it 'calls GET show' do
      response = @app.get('/identity')

      response.status.must_equal 200
      response.body.must_equal "{}"
    end

    it 'calls GET new' do
      response = @app.get('/identity/new')

      response.status.must_equal 200
      response.body.must_equal '{}'
    end

    it 'calls POST create' do
      response = @app.post('/identity', params: { identity: { avatar: { image: 'jodosha.png' } }})

      response.status.must_equal 200
      response.body.must_equal %({:identity=>{:avatar=>{:image=>\"jodosha.png\"}}})
    end

    it 'calls GET edit' do
      response = @app.get('/identity/edit')

      response.status.must_equal 200
      response.body.must_equal "{}"
    end

    it 'calls PATCH update' do
      response = @app.request('PATCH', '/identity', params: { identity: { avatar: { image: 'jodosha-2x.png' } }})

      response.status.must_equal 200
      response.body.must_equal %({:identity=>{:avatar=>{:image=>\"jodosha-2x.png\"}}})
    end

    it 'calls DELETE destroy' do
      response = @app.delete('/identity')

      response.status.must_equal 200
      response.body.must_equal "{}"
    end
  end

  describe 'resources' do
    it 'calls GET index' do
      response = @app.get('/flowers')

      response.status.must_equal 200
      response.body.must_equal '{}'
    end

    it 'calls GET show' do
      response = @app.get('/flowers/23')

      response.status.must_equal 200
      response.body.must_equal %({:id=>"23"})
    end

    it 'calls GET new' do
      response = @app.get('/flowers/new')

      response.status.must_equal 200
      response.body.must_equal '{}'
    end

    it 'calls POST create' do
      response = @app.post('/flowers', params: { flower: { name: 'Hanami' } })

      response.status.must_equal 200
      response.body.must_equal %({:flower=>{:name=>"Hanami"}})
    end

    it 'calls GET edit' do
      response = @app.get('/flowers/23/edit')

      response.status.must_equal 200
      response.body.must_equal %({:id=>"23"})
    end

    it 'calls PATCH update' do
      response = @app.request('PATCH', '/flowers/23', params: { flower: { name: 'Hanami!' } })

      response.status.must_equal 200
      response.body.must_equal %({:flower=>{:name=>"Hanami!"}, :id=>"23"})
    end

    it 'calls DELETE destroy' do
      response = @app.delete('/flowers/23')

      response.status.must_equal 200
      response.body.must_equal %({:id=>"23"})
    end

    describe 'with validations' do
      it 'automatically whitelists params from router' do
        response = @app.request('PATCH', '/painters/23', params: { painter: { first_name: 'Gustav', last_name: 'Klimt' } })

        response.status.must_equal 200
        response.body.must_equal %({:id=>"23", :painter=>{:first_name=>"Gustav", :last_name=>"Klimt"}})
      end
    end
  end
end
