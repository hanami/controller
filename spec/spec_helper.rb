$LOAD_PATH.unshift 'lib'
require 'hanami/utils'
require 'hanami/devtools/unit'
require 'hanami/controller'
require 'hanami/action/cookies'
require 'hanami/action/session'

Hanami::Utils.require!("spec/support")
