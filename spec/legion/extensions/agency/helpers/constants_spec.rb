# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Agency::Helpers::Constants do
  describe 'DEFAULT_EFFICACY' do
    it 'is 0.5 (moderate confidence)' do
      expect(described_class::DEFAULT_EFFICACY).to eq(0.5)
    end
  end

  describe 'EFFICACY_ALPHA' do
    it 'is a low positive float for slow adaptation' do
      expect(described_class::EFFICACY_ALPHA).to be_between(0.01, 0.5)
    end
  end

  describe 'asymmetric reinforcement' do
    it 'penalizes failure harder than it rewards success' do
      expect(described_class::FAILURE_PENALTY).to be > described_class::MASTERY_BOOST
    end
  end

  describe 'EFFICACY_SOURCES' do
    it 'contains Bandura four sources' do
      expect(described_class::EFFICACY_SOURCES).to contain_exactly(:mastery, :vicarious, :persuasion, :physiological)
    end

    it 'is frozen' do
      expect(described_class::EFFICACY_SOURCES).to be_frozen
    end
  end

  describe 'ATTRIBUTION_LEVELS' do
    it 'has four levels' do
      expect(described_class::ATTRIBUTION_LEVELS.size).to eq(4)
    end

    it 'has full_agency as highest' do
      expect(described_class::ATTRIBUTION_LEVELS[:full_agency]).to be > described_class::ATTRIBUTION_LEVELS[:no_agency]
    end

    it 'is frozen' do
      expect(described_class::ATTRIBUTION_LEVELS).to be_frozen
    end
  end

  describe 'OUTCOME_TYPES' do
    it 'includes success, failure, partial_success, unexpected' do
      expect(described_class::OUTCOME_TYPES).to contain_exactly(:success, :failure, :partial_success, :unexpected)
    end
  end

  describe 'EFFICACY_LABELS' do
    it 'has five levels' do
      expect(described_class::EFFICACY_LABELS.size).to eq(5)
    end

    it 'is frozen' do
      expect(described_class::EFFICACY_LABELS).to be_frozen
    end
  end

  describe 'bounds' do
    it 'has a floor above zero' do
      expect(described_class::EFFICACY_FLOOR).to be > 0.0
    end

    it 'has a ceiling below one' do
      expect(described_class::EFFICACY_CEILING).to be < 1.0
    end
  end
end
