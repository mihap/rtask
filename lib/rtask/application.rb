module RTask
  extend self
  def configure(&block) instance_eval &block; end;
 

  def run(options)
    @engine = init_app(options)
    prepare_tasks
    #TODO halt_on_errors
    execute
    finish_and_notify
  end

  
  def init_app(options)
    return Engine.new(options)
  end

  def prepare_tasks
    @engine.read_and_parse
  end

  def execute
    @engine.execute_all
  end

  def finish_and_notify
    @engine.tasks.each do | task | 
      task.notifier.report_all
    end
  end


end
