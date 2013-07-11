require 'lotus/http/status'

module Lotus
  module Action
    module Throwable
      protected

      def throw(code)
        status(*Http::Status.for_code(code))
        super :halt
      end

      def status(code, message)
        self.status = code
        self.body   = message
      end

      private
      def _rescue
        catch :halt do
          begin
            yield
          rescue
            throw 500
          end
        end
      end
    end
  end
end
