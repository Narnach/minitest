require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require 'mixins/rspec_mixin'

class Dummy
  include RspecMixin
end

describe RspecMixin do
  describe "#rspec" do
    before(:each) do
      @d = Dummy.new
      @d.stub!(:`).with('which spec').and_return('spec')
    end
    
    it "should return the command line string to execute" do
      @d.rspec([]).should == 'spec  %s' % @d.spec_opts
    end
  end
end