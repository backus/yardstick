# encoding: utf-8

require 'spec_helper'

describe Yardstick::Document, '#process_string' do
  subject(:measurements) { processor.process_string(method) }

  let(:processor) { Yardstick::Processor.new(config) }
  let(:config)    { Yardstick::Config.new            }

  let(:valid_method) do
    (<<-RUBY)
      # This is a method summary that is the maximum --- exactly 80 characters in length
      #
      # @example
      #   test('Hello World')  # => nil
      #
      # @param [#to_str] value
      #   the value
      #
      # @return [nil]
      #   returns nil
      #
      # @api public
      def test(value)
      end
    RUBY
  end

  def measurement(description)
    measurements.detect do |measurement|
      measurement.description == description
    end
  end

  describe 'with a method summary' do
    let(:method) { valid_method }

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should have a correct measurement' do
      expect(measurement('The method summary should be specified')).to be_ok
    end
  end

  describe 'without a method summary' do
    let(:method) { 'def test(value); end' }

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should have an incorrect measurement' do
      expect(measurement('The method summary should be specified')).to_not be_ok
    end
  end

  describe 'without a method summary when validations are turned off' do
    let(:config) do
      Yardstick::Config.new(rules: {
                              'Summary::Presence'.to_sym => { enabled: false }
                            })
    end
    let(:method) { 'def test(value); end' }

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should have a correct measurement' do
      expect(measurement('The method summary should be specified')).to be_ok
    end
  end

  describe 'without a method summary when validations are turned off for given class' do
    let(:config) do
      Yardstick::Config.new(rules: {
                              'Summary::Presence'.to_sym => { enabled: true, exclude: %w(World) }
                            })
    end
    let(:method) { 'class World; def test(value); end; end' }

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should have a correct measurement' do
      expect(measurements.detect { |measurement| measurement.description == 'The method summary should be specified' }).to be_ok
    end
  end

  describe 'with a method summary that is 80 characters in length' do
    let(:method) { valid_method }

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should have a correct measurement' do
      expect(measurement('The method summary should be less than 80 characters in length'))
        .to be_ok
    end
  end

  describe 'with a method summary that is 81 characters in length' do
    let(:method) do
      (<<-RUBY)
        # This is a method summary greater than the maximum - it is 81 characters in length
        def test(value)
        end
      RUBY
    end

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should have an incorrect measurement' do
      expect(measurement('The method summary should be less than 80 characters in length'))
        .to_not be_ok
    end
  end

  describe 'with a method summary that does not end in a period' do
    let(:method) { valid_method }

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should have a correct measurement' do
      expect(measurement('The method summary should not end in a period'))
        .to be_ok
    end
  end

  describe 'with a method summary that does end in a period' do
    let(:method) do
      <<-RUBY
        # This method summary ends in a period.
        def test(value)
        end
      RUBY
    end

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should have an incorrect measurement' do
      expect(measurement('The method summary should not end in a period'))
        .to_not be_ok
    end
  end

  describe 'with a method summary that is on one line' do
    let(:method) { valid_method }

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should have a correct measurement' do
      expect(measurement('The method summary should be a single line'))
        .to be_ok
    end
  end

  describe 'with a method summary that is not on one line' do
    let(:method) do
      <<-RUBY
        # This method summary
        # is on two lines
        def test(value)
        end
      RUBY
    end

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should have an incorrect measurement' do
      expect(measurement('The method summary should be a single line'))
        .to_not be_ok
    end
  end

  describe 'with a method that has an @example tag' do
    let(:method) { valid_method }

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should have a correct measurement' do
      expect(measurement('The public/semipublic method should have an example specified'))
        .to be_ok
    end
  end

  describe 'with a method that is private' do
    let(:method) do
      <<-RUBY
        # @api private
        def test(value)
        end
      RUBY
    end

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should be skipped' do
      expect(measurement('The public/semipublic method should have an example specified'))
        .to be_skip
    end
  end

  describe 'with a method that does not have an @example tag, and has an undefined @return tag' do
    let(:method) do
      <<-RUBY
        # @return [undefined]
        #
        # @api public
        def test(value)
        end
      RUBY
    end

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should be skipped' do
      expect(measurement('The public/semipublic method should have an example specified'))
        .to be_skip
    end
  end

  describe 'with a method that has an @api tag' do
    let(:method) { valid_method }

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should have a correct measurement' do
      expect(measurement('The @api tag should be specified'))
        .to be_ok
    end
  end

  describe 'with a method that does not have an @api tag' do
    let(:method) { 'def test(value); end' }

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should have an incorrect measurement' do
      expect(measurement('The @api tag should be specified'))
        .to_not be_ok
    end
  end

  describe 'with a method that has a public @api tag' do
    let(:method) { valid_method }

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should have a correct measurement' do
      expect(measurement('The @api tag must be either public, semipublic or private'))
        .to be_ok
    end
  end

  describe 'with a method that has an invalid @api tag' do
    let(:method) do
      <<-RUBY
        # @api invalid
        def test(value)
        end
      RUBY
    end

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should have an incorrect measurement' do
      expect(measurement('The @api tag must be either public, semipublic or private'))
        .to_not be_ok
    end
  end

  describe 'with a protected method and a semipublic @api tag' do
    let(:method) do
      <<-RUBY
        protected

        # @api semipublic
        def test(value)
        end
      RUBY
    end

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should have a correct measurement' do
      expect(measurement('A method with protected visibility must have an @api tag of semipublic or private'))
        .to be_ok
    end
  end

  describe 'with a protected method and a private @api tag' do
    let(:method) do
      <<-RUBY
        protected

        # @api private
        def test(value)
        end
      RUBY
    end

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should have a correct measurement' do
      expect(measurement('A method with protected visibility must have an @api tag of semipublic or private'))
        .to be_ok
    end
  end

  describe 'with a protected method and a public @api tag' do
    let(:method) do
      <<-RUBY
        protected

        # @api public
        def test(value)
        end
      RUBY
    end

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should have an incorrect measurement' do
      expect(measurement('A method with protected visibility must have an @api tag of semipublic or private'))
        .to_not be_ok
    end
  end

  describe 'with a private method and a private @api tag' do
    let(:method) do
      <<-RUBY
        private

        # @api private
        def test(value)
        end
      RUBY
    end

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should have a correct measurement' do
      expect(measurement('A method with private visibility must have an @api tag of private'))
        .to be_ok
    end
  end

  describe 'with a private method and a public @api tag' do
    let(:method) do
      <<-RUBY
        private

        # @api public
        def test(value)
        end
      RUBY
    end

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should have an incorrect measurement' do
      expect(measurement('A method with private visibility must have an @api tag of private'))
        .to_not be_ok
    end
  end

  describe 'with a private method and a semipublic @api tag' do
    let(:method) do
      <<-RUBY
        private

        # @api semipublic
        def test(value)
        end
      RUBY
    end

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should have an incorrect measurement' do
      expect(measurement('A method with private visibility must have an @api tag of private'))
        .to_not be_ok
    end
  end

  describe 'with a method that has a @return tag' do
    let(:method) { valid_method }

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should have a correct measurement' do
      expect(measurement('The @return tag should be specified')).to be_ok
    end
  end

  describe 'with a method that does not have a @return tag' do
    let(:method) { 'def test(value); end' }

    it { should be_kind_of(Yardstick::MeasurementSet) }

    it 'should have an incorrect measurement' do
      expect(measurement('The @return tag should be specified')).to_not be_ok
    end
  end
end
