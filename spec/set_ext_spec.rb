require File.join(File.dirname(__FILE__),'spec_helper')
require 'set_ext'

describe Set do
  describe "#join" do
    it 'should join the elements in its collection' do
      s = Set.new([1,2,3])
      s.join(" ").should == '1 2 3'
    end
  end
end