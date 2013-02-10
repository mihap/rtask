module RTask

  class Notifier

    def initialize(meths,task)
      meths.class == Array ? @methods = meths : @methods = [meths]
      @task = task
    end

    def report_all
      @methods.each do | meth |
        meth.run(@task)
      end
    end

    def report_max_time_exceed
      @methods.each do | meth |
        meth.run_exceed(@task)
      end
    end

  end





  class Report

    def run(task)
      #stub!
    end

  end

  class MailReport < Report

    def initialize
      @max_time_exceed_sent = false
    end  

    def run(task)
      body = []  
      if task.status 
        subject = "Task #{task.config[:name]} finished with status : #{task.status}"  
        body  << "<h2>Report</h2>"
        body << "<h3>Time start : #{task.time_start}</h3>"
        body << "<h3>Finished at : #{task.time_end}</h3>"
        if task.parser.errors.any? 
          body << "<h3>There was #{task.parser.errors.count} error(s) while parsing config files : <h3>"
          task.parser.errors.each do |err|
            body << "<p>#{err}</p>"
          end
        end
        body << "<h3>The task generated following output : </h3>"
        task.buffer.each do |line|
          body << "<p>#{line.chomp}</p>"
        end
      end

      if result = send_mail( template(subject,body), task.config[:mailto])
        RTask.master_log("#{result}")
      end

    end

    def run_exceed(task)
      body = []
      unless @max_time_exceed_sent

        subject = "Task #{task.config[:name]} : Time execution exceed specified in config file"
        body << "<h3>Time start : #{task.time_start}</h3>"
        
        body << "<h3>Last 10 lines of task's output  : </h3>"
        
        if last_10 = task.buffer.slice(task.buffer.count * -1,10)
          last_10.each do |line|
            body << "<p>#{line.chomp}</p>"
          end
        else
          body << "<p>No output</p>"
        end
        
        if result = send_mail(template(subject,body), task.config[:mailto])
          RTask.master_log("#{result}")
        else
          @max_time_exceed_sent = true
        end
      
      end

    end

    def send_mail(message,mailto)
      begin 
        Net::SMTP.start(*APP[:mailconfig].values, :login) do |smtp|
          smtp.send_message(message, 'mailrobot', mailto)
        end
      rescue Exception => e
        return e.message
      end
      return nil
    end


    def template(subject,body)
return message = <<TEMPLATE_END
From:  <mailrobot>
MIME-Version: 1.0
Content-type: text/html
Subject: #{subject}

#{body.join " "}
TEMPLATE_END
    end

  end


end

