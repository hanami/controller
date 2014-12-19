# Lotus::Controller
Complete, fast and testable actions for Rack

## v0.3.0 - 2014-12-23
### Added
- [Luca Guidi] Introduced `Action#request_id` as unique identifier for an incoming HTTP request
- [Luca Guidi] Introduced `Lotus::Controller.load!` as loading framework entry point
- [Kir Shatrov] Allow to define a default charset (`default_charset` configuration)
- [Kir Shatrov] Automatic content type with charset (eg `Content-Type: text/html; charset=utf-8`)
- [Michał Krzyżanowski] Allow to specify custom exception handlers: procs or methods (`exception_handler` configuration)
- [Karl Freeman & Lucas Souza] Introduced HTTP caching (`Cache-Control`, `Last-Modified`, ETAG, Conditional GET, expires)
- [Satoshi Amemiya] Introduced `Action::Params#to_h` and `#to_hash`
- [Luca Guidi] Added `#params` and `#errors` as default exposures
- [Luca Guidi] Introduced complete params validations
- [Luca Guidi & Matthew Bellantoni] Allow to whitelist params
- [Luca Guidi & Matthew Bellantoni] Allow to define custom classes for params via `Action.params`
- [Krzysztof Zalewski] Introduced `Action#format` as query method to introspect the requested mime type
- [Luca Guidi] Official support for Ruby 2.2

### Changed
- [Trung Lê] Renamed `Configuration#modules` to `#prepare`
- [Luca Guidi] Update HTTP status codes to IETF RFC 7231
- [Luca Guidi] When `Lotus::Controller` is included, don't inject code
- [Luca Guidi] Removed `Controller.action` as a DSL to define actions
- [Krzysztof Zalewski] Removed `Action#content_type` in favor of `#format=` which accepts a symbol (eg. `:json`)
- [Fuad Saud] Reduce method visibility where possible (Ruby `private` and `protected`)

### Fixed
- [Luca Guidi] Don't let exposures definition to override existing methods

## v0.2.0 - 2014-06-23
### Added
- [Luca Guidi] Introduced `Controller.configure` and `Controller.duplicate`
- [Luca Guidi] Introduced `Action.use`, that let to use a Rack middleware as a before callback
– [Luca Guidi] Allow to define a default mime type when the request is `Accept: */*` (`default_format` configuration)
– [Luca Guidi] Allow to register custom mime types and associate them to a symbol (`format` configuration)
- [Luca Guidi] Introduced `Configuration#handle_exceptions` to associate exceptions to HTTP statuses
- [Damir Zekic] Allow developers to toggle exception handling (`handle_exceptions` configuration)
- [Luca Guidi] Introduced `Controller::Configuration`
- [Luca Guidi] Official support for Ruby 2.1

### Changed
- [Luca Guidi] `Lotus::Action::Params` doesn't inherit from `Lotus::Utils::Hash` anymore
- [Luca Guidi] `Lotus::Action::CookieJar` doesn't inherit from `Lotus::Utils::Hash` anymore
- [Luca Guidi] Make HTTP status messages compliant with IANA and Rack
- [Damir Zekic] Moved `#throw` override logic into `#halt`, which keeps the same semantic

### Fixed
- [Krzysztof Zalewski] Reference exception in `rack.errors`

## v0.1.0 - 2014-02-23
### Added
- [Luca Guidi] Introduced `Action.accept` to whitelist accepted mime types
- [Luca Guidi] Introduced `Action#accept?` as a query method for the current request
- [Luca Guidi] Allow to whitelist handled exceptions and associate them to an HTTP status
- [Luca Guidi] Automatic `Content-Type`
- [Luca Guidi] Use `throw` as a control flow which understands HTTP status
- [Luca Guidi] Introduced opt-in support for HTTP/Rack cookies
- [Luca Guidi] Introduced opt-in support for HTTP/Rack sessions
- [Luca Guidi] Introduced HTTP redirect API
- [Luca Guidi] Introduced callbacks for actions: before and after
- [Luca Guidi] Introduced exceptions handling with HTTP statuses
- [Luca Guidi] Introduced exposures
- [Luca Guidi] Introduced basic actions compatible with Rack
- [Luca Guidi] Official support for Ruby 2.0
