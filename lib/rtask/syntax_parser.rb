module RTask
  class RTaskSyntaxError < StandardError; end;
  
  class SyntaxParser
    attr_reader :errors
    
    def initialize
      @rules = {
        name:         /\w+/,
        group:        /\w+/,
        mailto:       /^[_a-z0-9-]+(\.[_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*(\.[a-z]{2,4})$/,
        level:        /0|1/,
        max_time:     /^\d+$/,
        task_script:  SyntaxParser::ExecValidator }

      @mandatory = [:task_script]
      @errors = []
    end


    def parse(config)
      unknown_options = config.keys - @rules.keys
      if unknown_options.any?
        @errors << "Task file syntax error : #{unknown_options.join ' '}, ignoring"
        config.delete *unknown_options
      end

      config.each do | key, value | 
        unless @rules[key] =~ value.to_s 
          @errors << "Task file syntax error : `#{key}` not valid, ignoring" 
          config.delete key
        end
      end

      missing_options = @mandatory - config.keys
      if missing_options.any? 
        @errors << "Task file syntax error : missing mandatory option(s) `#{missing_options.join ", "}`"
        return [config, :missing]
      end
      return [config, :ok]
    end



    class ExecValidator
      def self.=~(name)
         return true if ( File.exists?(name) && File.executable?(name) )
      end
    end





  end

end