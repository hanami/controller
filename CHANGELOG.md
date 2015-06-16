# Lotus::Controller
Complete, fast and testable actions for Rack

## v0.4.4 - 2015-06-23
### Added
- [Luca Guidi] Security protection against Cross Site Request Forgery (CSRF).

### Fixed
- [Matthew Bellantoni] Ensure nested params to be correctly coerced to Hash.

## v0.4.3 - 2015-05-22
### Added
- [Alfonso Uceda Pompa & Luca Guidi] Introduced `Lotus::Action#send_file`
- [Alfonso Uceda Pompa] Set automatically `Expires` option for cookies when it's missing but `Max-Age` is present. Compatibility with old browsers.

## v0.4.2 - 2015-05-15
### Fixed
- [Luca Guidi] Ensure `Lotus::Action::Params#to_h` to return `::Hash` at the top level

## v0.4.1 - 2015-05-15
### Fixed
- [Luca Guidi] Ensure proper automatic `Content-Type` working well with Internet Explorer.
- [Luca Guidi] Ensure `Lotus::Action#redirect_to` to return `::String` for Rack servers compatibility.

### Changed
- [Alfonso Uceda Pompa] Prevent `Content-Type` and `Content-Lenght` to be sent when status code requires no body (eg. `204`).
    This is for compatibility with `Rack::Lint`, not with RFC 2016.
- [Luca Guidi] Ensure `Lotus::Action::Params#to_h` to return `::Hash`

## v0.4.0 - 2015-03-23
### Added
- [Erol Fornoles] `Action.use` now accepts a block
- [Alfonso Uceda Pompa] Introduced `Lotus::Controller::Configuration#cookies` as default cookie options.
- [Alfonso Uceda Pompa] Introduced `Lotus::Controller::Configuration#default_headers` as default HTTP headers to return in all the responses.
- [Luca Guidi] Introduced `Lotus::Action::Params#get` as a safe API to access nested params.

### Changed
- [Alfonso Uceda Pompa] `redirect_to` now is a flow control method: it terminates the execution of an action, including the callbacks.

## v0.3.2 - 2015-01-30
### Added
- [Alfonso Uceda Pompa] Callbacks: introduced `append_before` (alias of `before`), `append_after` (alias of `after`), `prepend_before` and `prepend_after`.
- [Alfonso Uceda Pompa] Introduced `Lotus::Action::Params#raw` which returns unfiltered data as it comes from an HTTP request.
- [Alfonso Uceda Pompa] `Lotus::Action::Rack.use` now fully supports Rack middleware, by mounting an internal `Rack::Builder` instance.
- [Simone Carletti] `Lotus::Action::Throwable#halt` now accepts an optional message. If missing it falls back to the corresponding HTTP status message.
- [Steve Hodgkiss] Nested params validation

### Fixed
- [Luca Guidi] Ensure HEAD requests will return empty body
- [Stefano Verna] Ensure HTTP status codes with empty body won't send body and non-entity headers.
- [Luca Guidi] Only dump exceptions in `rack.errors` if handling is turned off, or the raised exception is not managed.
- [Luca Guidi] Ensure params will return coerced values

## v0.3.1 - 2015-01-08
### Added
- [Lasse Skindstad Ebert] Introduced `Action#request` which returns an instance a `Rack::Request` compliant object: `Lotus::Action::Request`.

### Fixed
- [Steve Hodgkiss] Ensure params to return coerced values

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
