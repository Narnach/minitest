require File.join(File.dirname(__FILE__),'spec_helper')
require 'minitest'

describe Minitest do
  describe "#check" do
    describe 'run existing specs and tests', :shared => true do
      it 'should run its associated spec'
      it 'should run its associated test'
      it 'should skip non-existent specs'
      it 'should skip non-existent tests'
    end

    describe '(when a new file is created)' do
      it_should_behave_like 'run existing specs and tests'
    end

    describe '(when a file is changed)' do
      it_should_behave_like 'run existing specs and tests'
    end
  end

  describe "#start" do
    it 'should run #check periodically'
    describe "(when interrupted)" do
      it 'should run rcov on known specs and tests'
    end
  end
end