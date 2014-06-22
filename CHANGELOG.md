## v0.2.0
### Feb 23, 2014

48a5715 2014-06-22 **Luca Guidi** Made Lotus::Action#content_type public

2d7b0cc 2014-06-22 **Luca Guidi** Let to specify a default format for all the requests that aren't strict about the requested Mime type (eg. `*/*`).

401c1af 2014-06-19 **Luca Guidi** [breaking] Raise error if Lotus::Controller::Configuration#format doesn't receive the proper argument. Let Lotus::Action::Mime#accept to work with registered mime types

028ec2e 2014-06-19 **Luca Guidi** Make Lotus::Action::Mime#format a public method

ce42cd4 2014-06-19 **Luca Guidi** Detect the asked mime type and return the corresponding format

87323ad 2014-06-19 **Luca Guidi** Let actions to detect accepted mime type and to return the correct format symbol. Configuration can now register mime types

adf0357 2014-06-18 **Krzysztof Zalewski** [breaking] Implement Action#format

328153b 2014-06-17 **Luca Guidi** Bump version to v0.2.0

b2e5c85 2014-06-17 **Luca Guidi** Depend on lotus-utils ~> 0.2

166a3c8 2014-06-17 **Luca Guidi** Controller.duplicate can accept nil controllers namespace

c11bc96 2014-06-17 **Luca Guidi** Lotus::Controller: .duplicate => .dup, .generate => .duplicate

9488c66 2014-06-16 **Luca Guidi** Gem: build only with lib/ and essential files

cd7038c 2014-06-16 **Luca Guidi** [breaking] Removed Lotus::Action::Throwable#throw in favor of #halt

c200e68 2014-06-16 **Luca Guidi** Pretty print exceptions in rack.errors

3c122b0 2014-06-13 **Krzysztof Zalewski** Reference exception in rack.errors

9e64c3f 2014-06-11 **Luca Guidi** Let Lotus::Controller.generate to set action_module

f28d7e3 2014-06-11 **Luca Guidi** Introducing Lotus::Controller.generate as shortcut for .duplicate and .configure

af217ea 2014-06-08 **Luca Guidi** [breaking] Use composition over inheritance for Lotus::Action::Params

47e86db 2014-06-08 **Luca Guidi** [breaking] Use composition over inheritance for Lotus::Action::CookieJar

5e2a4a7 2014-05-28 **Luca Guidi** Allow standalone actions to inherit configuration from the right framework. Added Configuration#modules in order to configure the additional modules to include by default

ceb7214 2014-05-28 **Luca Guidi** Better Ruby idioms

075f9c3 2014-05-28 **Luca Guidi** Use the proper level of encapsulation for Configuration

431970c 2014-05-27 **Luca Guidi** Ensure the right level of duplication for Lotus::Controller

ae49c57 2014-05-27 **Luca Guidi** [breaking] Keep independent copies of framework, controller and action configurations. Introduced in action_module for configuration.

c56683a 2014-05-27 **Luca Guidi** [breaking] Introduced configuration for Controller and Action

8d39557 2014-05-10 **Luca Guidi** Added support for Ruby 2.1.2

c2854b6 2014-04-27 **Luca Guidi** Make HTTP status messages compliant with IANA and Rack

c137c3f 2014-04-27 **Luca Guidi** Implemented Action.use, that let to use a Rack middleware as a before callback

eb86286 2014-04-20 **Damir Zekic** Replace `#throw` override with `#halt` method

6da21f9 2014-03-17 **Damir Zekic** Allow exception handling to be disabled

c0ccb72 2014-02-24 **Luca Guidi Added support for Ruby 2.1.1

## v0.1.0
### Feb 23, 2014

f750e4c 2014-02-22 **Luca Guidi** Moved .handled_exceptions from Action to Controller, so that the place where to configure the framework will be easier to find for developers.

1de2a27 2014-02-17 **Luca Guidi** Added Lotus::Action.handle_exception

fd9e080 2014-02-13 **Luca Guidi** Implemented Lotus::Action.accept, in order to restrict the access when a non supported mime type is requested

516983f 2014-02-13 **Luca Guidi** Implemented Lotus::Action#accept?

634719a 2014-02-13 **Luca Guidi** Changed auto content type policy

7cce354 2014-02-12 **Luca Guidi** Use @_env instead of the argument in Lotus::Action::Callable#call

a41b43d 2014-02-12 **Luca Guidi** Extracted constants for Lotus::Action::Params

6bdf55b 2014-01-31 **Luca Guidi** Make session support optional

29c5f8c 2014-01-31 **Luca Guidi** Make cookies support optional

0b36afb 2014-01-31 **Luca Guidi** Removed Lotus::HTTP::Request and Response

25b2bcf 2014-01-31 **Luca Guidi** Return serialized Rack response (Array) instead of the object. Lotus::Action::Redirect no longer depends on Response. Lotus::Action::CookieJar no longer depends on Response, but on headers.

b306f4f 2014-01-31 **Luca Guidi** Lotus::Action::Rack#session no longer depends on Request

9a44477 2014-01-31 **Luca Guidi** Lotus::Action::Mime no longer depends on Request

9b7f524 2014-01-31 **Luca Guidi** Lotus::Action::CookieJar logic for cookies extraction/set/get is no longer dependant on Request and Response.

fc6de40 2013-09-24 **Luca Guidi** Don't wrap body if respond to #each

ce46399 2013-09-24 **Luca Guidi** Introducing factory for Response

83adc9c 2013-08-07 **Luca Guidi** Ensure to wrap body for HTTP::Response

0a41bf8 2013-08-07 **Luca Guidi** Introducing Lotus::HTTP::Request/Response

c44d440 2013-07-12 **Luca Guidi** Integration tests for sessions

e62b355 2013-07-11 **Luca Guidi** Added automatic Mime Type capabilities

351eb2f 2013-07-11 **Luca Guidi** Split features in proper `Lotus::Action` submodules.

9d268df 2013-07-10 **Luca Guidi** Introducing throw facility, to stop the request flow immediately.

73af6d1 2013-07-09 **Luca Guidi** Integration tests with Lotus::Router

6938fae 2013-07-05 **Luca Guidi** Implemented cookies facilities.

69f4c62 2013-07-02 **Luca Guidi** Rack compatibility

13bd2d2 2013-06-28 **Luca Guidi** Implemented #redirect_to

5adbee1 2013-06-28 **Luca Guidi** Implemented sessions support

4bb794d 2013-06-28 **Luca Guidi** Implemented action callbacks

3b792dc 2013-06-25 **Luca Guidi** Introducing Lotus::Controller

d279c48 2013-06-25 **Luca Guidi** Initial mess
