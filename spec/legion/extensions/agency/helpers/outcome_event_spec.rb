# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Agency::Helpers::OutcomeEvent do
  subject(:event) { described_class.new(domain: :coding, outcome_type: :success) }

  describe '#initialize' do
    it 'generates a uuid' do
      expect(event.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores domain' do
      expect(event.domain).to eq(:coding)
    end

    it 'stores outcome_type' do
      expect(event.outcome_type).to eq(:success)
    end

    it 'defaults source to mastery' do
      expect(event.source).to eq(:mastery)
    end

    it 'defaults magnitude to 1.0' do
      expect(event.magnitude).to eq(1.0)
    end

    it 'defaults attribution to full_agency' do
      expect(event.attribution).to eq(:full_agency)
    end

    it 'clamps magnitude to 0..1' do
      high = described_class.new(domain: :x, outcome_type: :success, magnitude: 5.0)
      low = described_class.new(domain: :x, outcome_type: :success, magnitude: -1.0)
      expect(high.magnitude).to eq(1.0)
      expect(low.magnitude).to eq(0.0)
    end

    it 'records timestamp' do
      expect(event.timestamp).to be_a(Time)
    end
  end

  describe '#success?' do
    it 'returns true for success' do
      expect(event.success?).to be true
    end

    it 'returns true for partial_success' do
      partial = described_class.new(domain: :x, outcome_type: :partial_success)
      expect(partial.success?).to be true
    end

    it 'returns false for failure' do
      failure = described_class.new(domain: :x, outcome_type: :failure)
      expect(failure.success?).to be false
    end

    it 'returns false for unexpected' do
      unexpected = described_class.new(domain: :x, outcome_type: :unexpected)
      expect(unexpected.success?).to be false
    end
  end

  describe '#attributed_magnitude' do
    it 'scales magnitude by attribution level' do
      full = described_class.new(domain: :x, outcome_type: :success, attribution: :full_agency)
      low = described_class.new(domain: :x, outcome_type: :success, attribution: :low_agency)
      expect(full.attributed_magnitude).to be > low.attributed_magnitude
    end

    it 'returns 0 for no_agency' do
      none = described_class.new(domain: :x, outcome_type: :success, attribution: :no_agency)
      expect(none.attributed_magnitude).to eq(0.0)
    end
  end

  describe '#to_h' do
    it 'returns all fields' do
      h = event.to_h
      expect(h).to include(:id, :domain, :outcome_type, :source, :magnitude, :attribution, :success, :attributed_magnitude, :timestamp)
    end
  end
end
