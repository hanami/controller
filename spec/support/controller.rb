Hanami::Controller::Configuration.class_eval do
  def ==(other)
    other.kind_of?(self.class) &&
      other.handled_exceptions == handled_exceptions
  end

  public :handled_exceptions
end

if defined?(Hanami::Action::CookieJar)
  Hanami::Action::CookieJar.class_eval do
    def include?(hash)
      key, value = *hash
      @cookies[key] == value
    end
  end
end
