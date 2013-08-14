module MetricsMachine
  class Mysql

    attr_reader :connection, :options

    def initialize connection, *args
      @options = args.extract_options!
      @connection = connection
    end

    def interval
      15
    end

    def statistics
      fetch_status.each do |k,v|
        fetch_status[k] = case v
        when "OFF", "NULL", "NONE"
          0
        when "ON", "TRUE"
          1
        else
          v.to_i    
        end
      end
    end

    private

    def fetch_status
      Hash[*connection.execute("SHOW GLOBAL STATUS").map.to_a.flatten]
    end

    def fetch_variables
      Hash[*connection.execute("SHOW GLOBAL VARIABLES").map.to_a.flatten]
    end
  end
end