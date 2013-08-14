require "metrics_machine/version"
require "metrics_machine/monitor"
require "statsd"
require "eventmachine"
require "erb"
require "psych"

module MetricsMachine
  autoload :Monitor, "metrics_machine/monitor"
  require "metrics_machine/railtie" if defined? Rails
  autoload :Mysql, "metrics_machine/mysql"

  def self.start options = {}, &block
    monitor.configure &block if block_given?

    p = lambda { EM.run { monitor.run! } }
    if defined?(PhusionPassenger)
      PhusionPassenger.on_event(:starting_worker_process) do |forked|
        if forked && EM.reactor_running?
          EM.stop
        end
    
        Thread.new &p
        die_gracefully_on_signal
      end
    else
      # faciliates debugging
      Thread.abort_on_exception = true
      # just spawn a thread and start it up
      Thread.new &p
    end
  end

  def self.monitor
    @monitor ||= Monitor.new reporter
  end

  def self.configure &block
    monitor.configure &block
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
      path = if defined? Rails and File.exists? "#{Rails.root}/config/statsd.yml"
               "#{Rails.root}/config/statsd.yml"
             else
               File.expand_path(File.join(File.dirname(__FILE__), "..", "config", "statsd.yml"))
             end
      data = Psych.load(ERB.new(IO.read(path)).result(binding))

      if defined? Rails
        data[Rails.env]
      else
        data["default"]
      end
    end
  end

end
