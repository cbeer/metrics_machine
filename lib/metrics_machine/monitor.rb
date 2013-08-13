require 'active_support/inflector/methods'
require 'active_support/inflector/transliterate'

module MetricsMachine
  class Monitor

    attr_reader :prefix, :monitors, :reporter

    def initialize reporter, options = {}, &block
      @reporter = reporter
      @monitors = {}
      @prefix = options.fetch(:prefix, self.class.default_prefix)
      instance_eval &block
      run!
    end

    def run!
      monitors.each do |name,monitor|
        EM.add_periodic_timer(monitor.interval) do
          report name, monitor
        end
      end
    end

    def report name, monitor
      monitor.statistics.each do |k,v|
        reporter.gauge "#{prefix}.#{name}.#{ActiveSupport::Inflector.underscore(k)}", v
      end
    end

    def monitor symbol_or_class, *args
      key = nil
      klass = case symbol_or_class
                when Symbol
                  MetricsMachine.const_get(symbol_or_class.to_s.capitalize)
                when Class
                  symbol_or_class
                when Hash
                  key = symbol_or_class.keys.first
                  symbol_or_class[key]
              end

      c = klass.new *args
      key ||= c.key if c.respond_to? :key
      key ||= klass.key if klass.respond_to? :key
      key ||= ActiveSupport::Inflector.underscore(klass.to_s.gsub('MetricsMachine::', ''))
      monitors[key] = c
    end

    def self.default_prefix
      `hostname`.strip
    end

  end
end