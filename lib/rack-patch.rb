# see https://github.com/rack/rack/pull/659
require 'rack'
require 'lotus/utils'

if Rack.release <= '1.5'
  require 'rack/utils'

  Rack::Utils.class_eval do
    def self.best_q_match(q_value_header, available_mimes)
      values = q_values(q_value_header)

      values = values.map do |req_mime, quality|
        match = available_mimes.find { |am| Rack::Mime.match?(am, req_mime) }
        next unless match
        [match, quality]
      end.compact

      values = values.reverse

      value  = values.sort_by do |match, quality|
        (match.split('/', 2).count('*') * -10) + quality
      end.last

      value.first if value
    end
  end
end
