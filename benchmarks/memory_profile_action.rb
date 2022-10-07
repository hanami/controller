# frozen_string_literal: true

require "hanami/action"
require "memory_profiler"

RETAIN = [] # rubocop:disable Style/MutableConstant

def inherit_action(times)
  times.times do
    RETAIN << Class.new(Hanami::Action).new
  end
end

times = Integer(ENV.fetch("TIMES", 100))

report = MemoryProfiler.report do
  inherit_action(times)
end

report.pretty_print
