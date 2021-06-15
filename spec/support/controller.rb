if defined?(Hanami::Action::CookieJar)
  Hanami::Action::CookieJar.class_eval do
    def include?(hash)
      key, value = *hash
      @cookies[key] == value
    end
  end
end
