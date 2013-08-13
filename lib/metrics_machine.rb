require "metrics_machine/version"
require "metrics_machine/monitor"
require "statsd"
require "eventmachine"
require "psych"

module MetricsMachine
  autoload :Monitor, "metrics_machine/monitor"
  autoload :Railtie, "metrics_machine/railtie"

  def self.start options = {}, &block

    thread = if defined?(PhusionPassenger)
               PhusionPassenger.on_event(:starting_worker_process) do |forked|
                 if forked && EM.reactor_running?
                   EM.stop
                 end
                 Thread.new { EM.run }
                 die_gracefully_on_signal
               end
             else
               # faciliates debugging
               Thread.abort_on_exception = true
               # just spawn a thread and start it up
               Thread.new {
                 EM.run
               }
             end

    Monitor.new reporter, options, &block if block_given?
    thread
  end

  def self.configure options = {}, &block
    Monitor.new reporter, options, &block if block_given?
  end

  def self.die_gracefully_on_signal
    Signal.trap("INT")  { EM.stop }
    Signal.trap("TERM") { EM.stop }
  end

  def self.reporter
    @statsd ||= Statsd.new(reporter_config['host'],reporter_config['port'])
  end

  private
  def self.reporter_config
    @reporter_config ||= begin
      path = if has_rails? and File.exists? "#{Rails.root}/config/statsd.yml"
               "#{Rails.root}/config/statsd.yml"
             else
               File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "statsd.yml"))
             end
      data = Psych.load_file(path)

      if has_rails?
        data[Rails.env]
      else
        data["default"]
      end
    end
  end

  def self.has_rails?
    const_defined? "Rails"
  end
end
