if ENV['COVERALL']
  require 'coveralls'
  Coveralls.wear!
end

require 'hanami/utils'
$LOAD_PATH.unshift 'lib'
require 'hanami/controller'
require 'hanami/action/cookies'
require 'hanami/action/session'

Hanami::Utils.require!("spec/support")
