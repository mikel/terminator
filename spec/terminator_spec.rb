#! /usr/bin/env bacon
 
require 'rubygems'
require 'bacon'

alias :doing :lambda

describe Terminator do
  
  describe "being given a contract to terminate" do
    it "should not complain about it" do
      doing { Terminator.terminate(1) { "Hello" } }.should_not raise_error
    end
    
    it "should not accept an expired contract" do
      doing { Terminator.terminate(0) { "Hello" } }.should.raise(Terminator::Error)
    end
    
    it "should not accept a late contract" do
      doing { Terminator.terminate(-0.1) { "Hello" } }.should.raise(Terminator::Error)
    end
    
    it "should handle fractions of seconts" do
      failed = false
      Terminator.terminate(0.3) do
        failed = true
      end
      failed.should.be.false
    end

  end

  describe "handling contracts" do
    it "should not kill it's mark if the mark completes" do
      failed = false
      Terminator.terminate(0.01) do
        failed = true
      end
      failed.should.be.false
    end

    it "should not terminate it's mark until the time is up" do
      failed = false
      Terminator.terminate(1) do
        sleep 0.9
        failed = true
      end
      failed.should.be.false
    end
    
    it "should handle multiple overlapping contracts gracefully" do
      first_job  = false
      second_job = false
      third_job  = false

      Terminator.terminate(0.3) do
        first_job = true
      end

      Terminator.terminate(0.3) do
        second_job = true
      end

      Terminator.terminate(0.3) do
        third_job = true
      end

      first_job.should.be.true
      second_job.should.be.true
      third_job.should.be.true
    end

    it "should be a surgical weapon only selectively destroying it's marks" do
      first_job  = false
      second_job = false

      begin
        Terminator.terminate(0.3) do
          sleep 0.4
          first_job = true
        end
      rescue 
        nil
      end
      
      Terminator.terminate(0.3) do
        second_job = true
      end

      first_job.should.be.false
      second_job.should.be.true
    end
    
    it "should a surgical weapon only selectively destroying it's marks - backwards" do
      first_job  = false
      second_job = false
      
      Terminator.terminate(0.3) do
        first_job = true
      end

      begin
        Terminator.terminate(0.3) do
          sleep 0.4
          second_job = true
        end
      rescue 
        nil
      end

      first_job.should.be.true
      second_job.should.be.false
      
    end
    
    it "should accept an optional trap handler" do
      trap = lambda{ 'You failed me again!' }
      
      doing {
        Terminator.terminate(0.001, :trap => trap) do
          sleep 0.2
          job = true
        end }.should.raise(Terminator::Error)

    end
    
  end

end

BEGIN {
  rootdir = File.split(File.expand_path(File.dirname(File.dirname(__FILE__))))
  libdir = File.join(rootdir, 'lib')
  require File.join(libdir, 'terminator')
}
