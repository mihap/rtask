module RTask

  class Task
    
    attr_reader  :time_start, :reader, :writer, :buffer, :config, :notifier, :parser
    attr_accessor  :time_end, :pid, :status

    def initialize(filename)
      @state = :init
      @rtask_filename = filename
      @buffer = Array.new
      @tasks = Array.new
      @parser = SyntaxParser.new
    end

    def read_config_file
      @state = :read_config
      @config = {}
      File.readlines(@rtask_filename).each do |line|
        if line =~ /\w+/ && line !~ /^(\s)?#/
          var, value = line.split(/\s+/,2)
          @config[var.to_sym] = value.chomp
        end
      end rescue nil

      merge_defaults
      validate_config 
      setup_notifier
    end

    def merge_defaults
      #TODO read .rtaskrc and fill up needed fields 
    end


    def validate_config
      @state = :syntax_check
      @config, valid = @parser.parse(@config)

      unless valid == :ok
        stop "Interrupted due to fatal error(s) in rtask file exit 1"
      end 

      @parser.errors.each do | error |
        RTask.master_log "#{error} while checking #{@rtask_filename}", :err
      end

    end


    def setup_logger
      @logger = Logger.new("#{APP[:log_dir]}/#{File.basename(@rtask_filename).sub(".rtask",".log")}", File::WRONLY | File::APPEND)
      @logger.level = Logger::INFO
      @logger.datetime_format = "%Y%m%d %H:%M:%S"
      @logger.formatter = proc do |severity, datetime, progname, msg|
          "[#{@pid}] #{datetime}: #{msg}"
      end
    end

    def start
      @state = :start
      @time_start = Time.now
      @reader, @writer = IO.pipe
    end

    def stop(status)
      @state = :finished
      @time_end = Time.now
      @status = status
    end


    def run
      $stdout.reopen(@writer)
      $stderr.reopen(@writer)
      exec("\"#{@config[:task_script]}\"")
    end

    def shutdown
      reader.close
    end

    def to_buffer(message)
      @buffer << message
      @logger.info message
    end

    def finished?
      @state == :finished
    end

    def running?
      @state == :start
    end

    def lingering?
      return Time.now >= @time_start + @config[:max_time].to_i if @config[:max_time]
    end

    def setup_notifier
      reporters = []
      reporters << MailReport.new if @config && @config[:mailto]
      @notifier = Notifier.new(reporters,self)
    end


  end

 

end