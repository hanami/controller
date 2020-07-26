require "hanami/action/view_name_inferrer"

require "dry/inflector"
require "hanami/action/application_configuration"

RSpec.describe Hanami::Action::ViewNameInferrer, ".call" do
  subject(:view_name) {
    described_class.(
      action_name: action_name,
      provider: provider
    )
  }

  let(:provider) {
    double(
      :provider,
      application: application,
      inflector: Dry::Inflector.new,
      namespace_path: provider_namespace_path
    )
  }
  let(:provider_namespace_path) { "main" }

  let(:application) { double(:application) }
  let(:application_actions_config) { Hanami::Action::ApplicationConfiguration.new }

  before do
    allow(application).to receive_message_chain("config.actions") { application_actions_config }
  end

  context "named action" do
    let(:action_name) { "Main::Actions::Articles::Index" }

    it { is_expected.to eq ["views.articles.index"] }
  end

  context "RESTful create action" do
    let(:action_name) { "Main::Actions::Articles::Create" }

    it { is_expected.to eq ["views.articles.create", "views.articles.new"] }
  end

  context "RESTful update action" do
    let(:action_name) { "Main::Actions::Articles::Update" }

    it { is_expected.to eq ["views.articles.update", "views.articles.edit"] }
  end
end
