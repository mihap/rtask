module RTask


  class Engine

    attr_reader :tasks

    # {tasks:[],dirs:[],groups:[]}
    def initialize(options)
      @tasks = []
      options[:dirs] << APP[:location] if options[:dirs].empty? && options[:tasks].empty?
      rtask_list = [] 

      options[:dirs].each do |dir|
        begin
          list = Dir.entries(File.absolute_path(dir)).select { |item| item =~ /\.rtask/ } 
          raise Errno::ENOENT, "Directory #{dir} not contains any rtask files" if list.empty?
          rtask_list += list.map { |item| File.absolute_path("#{dir}/#{item}")}
        rescue Errno::ENOENT => e
          RTask.master_log("#{e.message}",APP[:halt_on_error] ? :crit : :warning)
          exit 1 if APP[:halt_on_error]
        end
      end
      
      options[:tasks].each do |task|
        begin
          raise Errno::ENOENT unless File.exists?(File.absolute_path(task))
          rtask_list << File.absolute_path(task)  
        rescue Errno::ENOENT => e
          RTask.master_log("#{e.message}",APP[:halt_on_error] ? :crit : :warning)
          exit 1 if APP[:halt_on_error]
        end
      end
    
      rtask_list.each do |file|
        @tasks << Task.new(file)
      end

    end


    def read_and_parse
      @tasks.each { |task| task.read_config_file }
    end


    def execute_all
      executable = @tasks.reject(&:finished?) 
      
      executable.each do | ex |
        ex.start
        ex.pid = fork do
          ex.reader.close
          ex.run
        end
        ex.writer.close
        ex.setup_logger 
      end
    trap_dead_workers
    supervise
    end
    
  def trap_dead_workers
    trap(:CHLD) do
      begin
        while pid = Process.waitpid2(-1, Process::WNOHANG)
          @tasks.find { |task| task.pid == pid[0] }.stop(pid[1])
          break unless @tasks.find(&:running?)
        end
      rescue Errno::ECHILD
      end
    end
  end

  def check_lingering_processes
    @tasks.select(&:lingering?).each do |task|
      task.notifier.report_max_time_exceed
    end
  end

  def supervise
    timeout = 5 
    loop do

      busy_workers = @tasks.select { |task| task.reader && !task.reader.closed? }
      break if busy_workers.empty?

      ready_for_read = IO.select(busy_workers.map { |worker| worker.reader },nil,nil,timeout)
      if ready_for_read
        ready_for_read[0].each do |io|
          worker = @tasks.find { |task| task.reader == io }
          begin
            message = io.gets
            if message
              worker.to_buffer message
            else
              # nil == EOF
              worker.shutdown
            end
          end while message

        end
      end
      check_lingering_processes      

    end

  end




  end







end