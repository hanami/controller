module Lotus
  module Action
    module Throwable
      module Handlers
        ::Rack::Utils::SYMBOL_TO_STATUS_CODE.each do |symbol, code|
          define_method symbol do |exception|
            halt(code)
          end
          private symbol
        end
      end
    end
  end
end

