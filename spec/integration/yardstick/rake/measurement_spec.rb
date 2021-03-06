# encoding: utf-8

require 'spec_helper'
require 'yardstick/rake/measurement'

describe Yardstick::Rake::Measurement do
  let(:output) { Pathname('measurements/report.txt') }

  before do
    output.dirname.rmtree if output.dirname.exist?

    Yardstick::Rake::Measurement.new do |config|
      config.path = 'lib/yardstick.rb'
    end
  end

  it 'should write the report' do
    Rake::Task['yardstick_measure'].execute
    expect(output.read)
      .to eql("\nYARD-Coverage: 100.0%  Success: 30  Failed: 0  Total: 30\n")
  end
end
