# Terminator

## Summary

An external timeout mechanism based on processes and signals.  Safe for 
system calls.  Safe for minors.  but not very safe for misbehaving, 
downtrodden zombied out processes.
  
## Description

Terminator is a solution to the problem of 'how am I meant to kill a
system call in Ruby!?'

Ruby (at least MRI) uses green threads to "multitask".  This means that
there is really only ever one ruby process running which then splits up
it's processor time between all of it's threads internally.

The processor then only has to deal with one ruby process and the ruby 
process deals with all it's threads.  There are pros and cons to this
method, but that is not the point of this library.

The point is, that if you make a system call to an external resource from
ruby, then the kernel will go and make that call for ruby and NOT COME BACK
to ruby until that system call completes or fails.  This can take a very 
long time and is why your feeble attempts at using ruby's internal "Timeout"
command has failed miserably at timing out your external web service, database
or network connections.

You see, Ruby just doesn't get a chance to do anything as the kernel goes
"I'm not going to talk to you again until your system calls complete". Sort
of a no win situation for Ruby.

That's where Terminator comes in.  Like Arnie, he will come back.  No matter
what, and complete his mission, unless he gets aborted before his timeout,
you can trust Terminator to thoroughly and without remorse, nuke your 
misbehaving and timing out ruby processes efficiently, and quickly.

## How does it work?

Basically we create a new terminator ruby process, separate to the existing
running ruby process that has a simple command of sleep for x seconds, and then
do a process TERM on the PID of the original ruby process that created it.

If your process finishes before the timeout, it will kill the Terminator first.

So really it is a race of who is going to win?

Word of warning though.  Terminator is not subtle.  Don't expect it to split
hairs.  Trying to give a process that takes about 1 second to complete, a
2 second terminator... well... odds are 50/50 on who is going to make it.

If you have a 1 second process, give it 3 seconds to complete.  Arnie doesn't
much care for casualties of war.

Another word of warning, if using Terminator inside a loop, it is possible
to exceed your open file limit.  I have safely tested looping 1000 times
  
## How to install?

```bash
gem install terminator
```

## History

  0.4.2
    * initial version (ara)
  0.4.3
    * added some extra specs and test cases (mikel)
  0.4.4
    * made terminator loop safe.  1000.times { Terminator.timeout(1) do true; end }
      now works (mikel)
    * added more test cases (mikel)

## Authors

* [ara.t.howard](http://github.com/ahoward)
* [mikel lindsaar](http://github.com/mikel)

## Sampes

### Basic terminator usage:

```ruby
# samples/a.rb

require 'terminator'

Terminator.terminate 2 do
  sleep 4
end
```

Results in:

```bash
$ ruby samples/a.rb

samples/a.rb:3: 2s (Terminator::Error)
	from samples/a.rb:3
```

### Simple rescue in action:

```ruby
# samples/b.rb

require 'terminator'

Terminator.terminate 0.2 do
  sleep 0.4 rescue puts 'timed out!'
end
```

Results in:

```bash
$ ruby samples/b.rb

timed out!
```

### Passing timeout in as a hash

```ruby
# samples/c.rb

require 'terminator'

begin
  Terminator.terminate :seconds => 0.2 do
    sleep 0.4
  end
rescue Terminator.error
  puts 'timed out!'
end
```

Results in:

```bash
$ ruby samples/c.rb

timed out!
```

### Running a code block lambda on timeout

```ruby
# samples/d.rb

require 'terminator'

trap = lambda{ puts "signaled @ #{ Time.now.to_i }" }

Terminator.terminate :seconds => 1, :trap => trap do
  sleep 2
  puts "woke up  @ #{ Time.now.to_i }"
end
```

Results in:

```bash
$ ruby samples/d.rb

signaled @ 1221026177
woke up  @ 1221026178
```

### Can we loop?  Yes we can!

```ruby
#  samples/e.rb

require 'terminator'

puts "Looping 1000 times on the terminator..."
success = false
1.upto(1000) do |i|
  success = false
  Terminator.terminate(1) do
    success = true
  end
  print "\b\b\b#{i}"
end
puts "\nI was successful" if success
```

Results in:

```bash
$ ruby samples/e.rb
  
Looping 1000 times on the terminator...
1000
I was successful
```
