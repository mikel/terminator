require 'rbconfig'
require 'tempfile'

require 'fattr'

module Terminator
  Version = '0.4.3'

  def terminate options = {}, &block
    options = { :seconds => Float(options).to_f } unless Hash === options 

    seconds = getopt :seconds, options

    raise ::Terminator::Error, "Time to kill must be greater than 0" unless seconds > 0

    trap = getopt :trap, options, lambda{ eval("raise(::Terminator::Error, 'Timeout out after #{ seconds }s')", block) }

    handler = Signal.trap(signal, &trap)

    plot_to_kill pid, :in => seconds, :with => signal

    begin
      block.call
    ensure
      Signal.trap(signal, handler)
    end
  end

  def plot_to_kill pid, options = {}
    seconds = getopt :in, options
    signal = getopt :with, options
    process.puts [pid, seconds, signal].join(' ')
    process.flush
  end

  fattr :process do
    process = IO.popen "#{ ruby } #{ program.inspect }", 'w+'
    at_exit do
      begin
        Process.kill -9, process.pid
      rescue Object
      end
    end
    process.sync = true
    process
  end

  fattr :program do
    code = <<-code
      while(( line = STDIN.gets ))
        pid, seconds, signal, *ignored = line.strip.split

        pid = Float(pid).to_i
        seconds = Float(seconds)
        signal = Float(signal).to_i rescue String(signal)

        sleep seconds

        begin
          Process.kill signal, pid
        rescue Object
        end
      end
    code
    tmp = Tempfile.new "#{ ppid }-#{ pid }-#{ rand }" 
    tmp.write code
    tmp.close
    tmp.path
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
