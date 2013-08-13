module MetricsMachine
  class Railtie < Rails::Railtie

    initializer "metricsmachine.start_em" do
      unless EM.reactor_running?
        MetricsMachine.start
      end
    end

    initializer "metricsmachine.configure_rails_initialization" do
      MetricsMachine.configure do
        monitor :mysql, ActiveRecord::Base.connection if ActiveRecord::Base.connection.is_a? ActiveRecord::ConnectionAdapters::Mysql2Adapter
      end
    end

  end
end