#! /usr/bin/env bacon
 
require 'rubygems'
require 'bacon'

describe Terminator do
  it 'should have some tests' do
    0b101010.should == 42
  end
end

BEGIN {
  rootdir = File.split(File.expand_path(File.dirname(File.dirname(__FILE__))))
  libdir = File.join(rootdir, 'lib')
  require File.join(libdir, 'terminator')
}
