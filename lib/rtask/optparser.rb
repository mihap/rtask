require 'optparse'



class OptParser
 

  def self.parse
    options = { :groups => [], :dirs => [], :tasks => []}
    exclusive = [["-g","-t"]]

    args_injector = lambda { |key,arg|
      start, current = [ARGV.index(arg), ARGV.index(arg) + 1]
      while (next_arg = ARGV[current] && ARGV[current] !~ /^-/) do  
        options[key] << ARGV[current] 
        current+=1
      end
      ARGV.slice!(start,current - start)
    }


    parser = OptionParser.new do |opts|
      opts.banner = "Usage : rtask <task | directory> <options>.\n If no options given, executes all tasks in current directory"

      opts.on "-g", "--group GROUP", 
        "Execute group of tasks" do |arg|
         args_injector.call(:groups,"-g") 
      end

      opts.on "-t", "--tasks TASK", 
        "Execute task" do |arg|
        args_injector.call(:tasks,"-t")
      end

      opts.on "-d", "--directory DIRECTORY",
      "Execute all tasks in DIRECTORY" do |arg|
      args_injector.call(:dirs,"-d")
      end

    end

    parser.on_tail "-h", "--help", "Show help" do
      puts parser
      exit 1
    end

    exclusive.each do |ex| 
      if ex & ARGV == ex
        puts "Options #{ex.join " "} are mutual exclusive ", parser 
        exit 1
      end
    end

    begin 
      parser.parse(ARGV)
    rescue *[OptionParser::InvalidOption, OptionParser::MissingArgument] => e
      exit 1
    end
    
    if ARGV.count != 0

      if options[:tasks].any? || options[:dirs].any?
        puts parser
        exit 1
      end

      while arg = ARGV.pop 
        options[:dirs]  << arg && next if File.directory?(arg)
        options[:tasks] << arg && next if File.exists?(arg) && options[:groups].empty? 
        options[:tasks] << "#{arg}.rtask" && next if File.exists?("#{arg}.rtask") && options[:groups].empty?
        puts "Directory or file #{arg} not found ", parser
        exit 1
      end

    end   

    return options
  end 

end