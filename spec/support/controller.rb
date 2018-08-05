# frozen_string_literal: true

Hanami::Controller.class_eval do
  def self.unload!
    self.configuration = configuration.duplicate
    configuration.reset!
  end
end

Hanami::Controller::Configuration.class_eval do
  def ==(other)
    other.is_a?(self.class) &&
      other.handle_exceptions  == handle_exceptions &&
      other.handled_exceptions == handled_exceptions &&
      other.action_module      == action_module
  end

  public :handled_exceptions # rubocop:disable Style/AccessModifierDeclarations
end

if defined?(Hanami::Action::CookieJar)
  Hanami::Action::CookieJar.class_eval do
    def include?(hash)
      key, value = *hash
      @cookies[key] == value
    end
  end
end
