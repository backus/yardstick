# encoding: utf-8

require 'spec_helper'

describe Yardstick::Config, '#path=' do
  subject { described_class.new }

  before { subject.path = '/tmp/*.rb' }

  its(:path) { should eql('/tmp/*.rb') }
end
