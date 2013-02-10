
require 'logger'
require 'net/smtp'
require 'syslog'
require_relative 'rtask/version.rb'
require_relative 'rtask/syntax_parser.rb'
require_relative 'rtask/notifier.rb'
require_relative 'rtask/task.rb'
require_relative 'rtask/engine.rb'
require_relative 'rtask/application.rb'
require_relative 'rtask/config.rb'

at_exit {  RTask.master_log "Exiting"}


