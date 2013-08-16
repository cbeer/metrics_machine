require 'spec_helper'

describe MetricsMachine do

  DummyMonitor = Class.new do
    def interval
      1
    end

    def statistics
      { "some-value" => 50 }
    end
  end

  it 'should do something' do

    reporter = double()

    reporter.should_receive(:gauge).at_least(3).at_most(6).times.with("metrics_machine.dummy_monitor.some_value", 50)
    MetricsMachine::Monitor.stub(:default_prefix => "metrics_machine")

    MetricsMachine.stub(:reporter => reporter)
    

    thread = MetricsMachine.start  do
      monitor DummyMonitor
    end

    sleep 5

  end
end