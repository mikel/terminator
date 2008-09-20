require 'rbconfig'
require 'fattr'

# The terminator library is simple to use.
#
#  require 'terminator'
#  Terminator.terminate(1) do
#    sleep 4
#    puts("I will never print")
#  end
#  #=> Terminator::Error: Timeout out after 1s
#
# The above code snippet will raise a Terminator::Error as the terminator's timeout is 
# 2 seconds and the block will take at least 4 to complete.
#
# You can put error handling in with a simple begin / rescue block:
#
#  require 'terminator'
#  begin
#    Terminator.terminate(1) do
#      sleep 4
#      puts("I will never print")
#    end
#  rescue
#    puts("I got terminated")
#  end
#  #=> I got terminated, but rescued myself.
#
# The standard action on termination is to raise a Terminator::Error, however, this is
# just an anonymous object that is called, so you can pass your own trap handling by
# giving the terminator a lambda as an argument.
#
#  require 'terminator'
#  custom_trap = lambda { eval("raise(RuntimeError, 'Oops... I failed...')") }
#  Terminator.terminate(:seconds => 1, :trap => custom_trap) do
#    sleep 10
#  end
#  #=> RuntimeError: (eval):1:in `irb_binding': Oops... I failed...
#
module Terminator
  Version = '0.4.3'

  # Terminator.terminate has two ways you can call it.  You can either just specify:
  #
  #  Terminator.terminate(seconds) { code_to_execute }
  #
  # where seconds is an integer number greater than or equal to 1.  If you pass a float
  # in on seconds, Terminator will call to_i on it and convert it to an integer.  This 
  # is because Terminator is not a precise tool, due to it calling a new ruby instance,
  # and spawning a new process, relying on split second accuracy is a folly.
  #
  # If you want to pass in the block, please use:
  #
  #  Terminator.terminate(:seconds => seconds, :trap => block) { code_to_execute }
  #
  # Where block is an anonymous method that gets called when the timeout occurs.
  def terminate options = {}, &block
    options = { :seconds => Float(options).to_i } unless Hash === options 

    seconds = getopt :seconds, options

    raise ::Terminator::Error, "Time to kill must be at least 1 second" unless seconds >= 1

    trap = getopt :trap, options, lambda{ eval("raise(::Terminator::Error, 'Timeout out after #{ seconds }s')", block) }

    handler = Signal.trap(signal, &trap)

    terminator_pid = plot_to_kill pid, :in => seconds, :with => signal

    begin
      block.call
      nuke_terminator(terminator_pid)
    ensure
      Signal.trap(signal, handler)
    end
  end

  private

  def nuke_terminator(pid)
    Process.kill("KILL", pid) rescue nil
    Process.wait(pid)
  end

  def plot_to_kill pid, options = {}
    seconds = getopt :in, options
    signal = getopt :with, options
    send_terminator(pid, seconds)
  end

  def send_terminator(pid, seconds)
    process = IO.popen(%[#{ ruby } -e'sleep #{seconds}.to_i; Process.kill("#{signal}", #{pid}) rescue nil;'], 'w+')
    process.pid
  end

  def temp_file_name
    "terminator-#{ ppid }-#{ pid }-#{ rand }"
  end

  fattr :ruby do
    c = ::Config::CONFIG
    ruby = File::join(c['bindir'], c['ruby_install_name']) << c['EXEEXT']
    raise "ruby @ #{ ruby } not executable!?" unless test(?e, ruby)
    ruby
  end

  fattr :pid do
    Process.pid
  end

  fattr :ppid do
    Process.ppid
  end

  fattr :signal do
    'TERM'
  end

  def getopt key, hash, default = nil
    return hash.fetch(key) if hash.has_key?(key)
    key = key.to_s
    return hash.fetch(key) if hash.has_key?(key)
    key = key.to_sym
    return hash.fetch(key) if hash.has_key?(key)
    default
  end

  class Error < ::StandardError; end
  def error() ::Terminator::Error end
  def version() ::Terminator::Version end

  extend self
end
