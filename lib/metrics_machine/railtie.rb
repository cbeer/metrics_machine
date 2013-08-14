module MetricsMachine
  class Railtie < Rails::Railtie

    if Rails.env.production? || ENV['METRICS'] == "true"
      initializer "metricsmachine.initialization" do
        MetricsMachine.start do
          monitor :mysql, ActiveRecord::Base if ActiveRecord::Base.connection.is_a? ActiveRecord::ConnectionAdapters::Mysql2Adapter
        end
      end
    end

  end
end