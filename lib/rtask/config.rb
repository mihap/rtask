RTask.configure do

  APP = {
    name:       'rtask',
    location:   Dir.pwd,
    log_dir:    ENV["HOME"], # where to log worker processes output
    halt_on_error: false,
    
    mailconfig: {
      address:  "b-com.co.il",
      port:     25,
      helo:     "localhost",
      username: "mailrobot@b-com.co.il",
      password: "Creshendo123"
    }

  }

  #log levels 
  #  emerg
  #  alert
  #  crit
  #  err
  #  warning
  #  notice
  #  info
  #  debug

  def master_log(message,level = :info)
    puts "#{level.to_s.upcase if level != :info} #{message}" if $stdout.tty? 
    Syslog.open("RTask", Syslog::LOG_PID | Syslog::LOG_CONS) { |s| s.send(level,message) }
  end

end
