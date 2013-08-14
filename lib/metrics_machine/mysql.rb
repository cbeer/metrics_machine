module MetricsMachine
  class Mysql

    attr_reader :base, :options

    def initialize base, *args
      @options = args.extract_options!
      @base = base
    end

    def interval
      15
    end

    def statistics
      status = fetch_status

      status.each do |k,v|
        status[k] = case v
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
      Hash[*base.connection.execute("SHOW GLOBAL STATUS").map.to_a.flatten]
    end

    def fetch_variables
      Hash[*base.connection.execute("SHOW GLOBAL VARIABLES").map.to_a.flatten]
    end
  end
end