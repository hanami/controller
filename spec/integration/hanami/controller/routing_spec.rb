require 'hanami/router'

Routes = Hanami::Router.new do
  get '/',         to: 'root'
  get '/team',     to: 'about#team'
  get '/contacts', to: 'about#contacts'

  resource  :identity
  resources :flowers
  resources :painters, only: [:update]
end

RSpec.describe 'Hanami::Router integration' do
  let(:app) { Rack::MockRequest.new(Routes) }

  it "calls simple action" do
    response = app.get("/")

    expect(response.status).to            be(200)
    expect(response.body).to              eq("{}")
    expect(response.headers["X-Test"]).to eq("test")
  end

  it "calls a controller's class action" do
    response = app.get("/team")

    expect(response.status).to            be(200)
    expect(response.body).to              eq("{}")
    expect(response.headers["X-Test"]).to eq("test")
  end

  it "calls a controller's action (with DSL)" do
    response = app.get("/contacts")

    expect(response.status).to be(200)
    expect(response.body).to   eq("{}")
  end

  it "returns a 404 for unknown path" do
    response = app.get("/unknown")

    expect(response.status).to be(404)
  end

  context "resource" do
    it "calls GET show" do
      response = app.get("/identity")

      expect(response.status).to be(200)
      expect(response.body).to   eq("{}")
    end

    it "calls GET new" do
      response = app.get("/identity/new")

      expect(response.status).to be(200)
      expect(response.body).to   eq("{}")
    end

    it "calls POST create" do
      response = app.post("/identity", params: { identity: { avatar: { image: "jodosha.png" } } })

      expect(response.status).to be(200)
      expect(response.body).to   eq(%({:identity=>{:avatar=>{:image=>\"jodosha.png\"}}}))
    end

    it "calls GET edit" do
      response = app.get("/identity/edit")

      expect(response.status).to be(200)
      expect(response.body).to   eq("{}")
    end

    it "calls PATCH update" do
      response = app.request("PATCH", "/identity", params: { identity: { avatar: { image: "jodosha-2x.png" } } })

      expect(response.status).to be(200)
      expect(response.body).to   eq(%({:identity=>{:avatar=>{:image=>\"jodosha-2x.png\"}}}))
    end

    it "calls DELETE destroy" do
      response = app.delete("/identity")

      expect(response.status).to be(200)
      expect(response.body).to   eq("{}")
    end
  end

  context "resources" do
    it "calls GET index" do
      response = app.get("/flowers")

      expect(response.status).to be(200)
      expect(response.body).to   eq("{}")
    end

    it "calls GET show" do
      response = app.get("/flowers/23")

      expect(response.status).to be(200)
      expect(response.body).to   eq(%({:id=>"23"}))
    end

    it "calls GET new" do
      response = app.get("/flowers/new")

      expect(response.status).to be(200)
      expect(response.body).to   eq("{}")
    end

    it "calls POST create" do
      response = app.post("/flowers", params: { flower: { name: "Sakura" } })

      expect(response.status).to be(200)
      expect(response.body).to   eq(%({:flower=>{:name=>"Sakura"}}))
    end

    it "calls GET edit" do
      response = app.get("/flowers/23/edit")

      expect(response.status).to be(200)
      expect(response.body).to   eq(%({:id=>"23"}))
    end

    it "calls PATCH update" do
      response = app.request("PATCH", "/flowers/23", params: { flower: { name: "Sakura!" } })

      expect(response.status).to be(200)
      expect(response.body).to   eq(%({:flower=>{:name=>"Sakura!"}, :id=>"23"}))
    end

    it "calls DELETE destroy" do
      response = app.delete("/flowers/23")

      expect(response.status).to be(200)
      expect(response.body).to   eq(%({:id=>"23"}))
    end

    context "with validations" do
      it "automatically whitelists params from router" do
        response = app.request("PATCH", "/painters/23", params: { painter: { first_name: "Gustav", last_name: "Klimt" } })

        expect(response.status).to be(200)
        expect(response.body).to   eq(%({:painter=>{:first_name=>"Gustav", :last_name=>"Klimt"}, :id=>"23"}))
      end
    end
  end
end
