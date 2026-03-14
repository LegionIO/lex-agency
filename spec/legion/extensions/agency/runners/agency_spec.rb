# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Agency::Runners::Agency do
  let(:runner) do
    obj = Object.new
    obj.extend(described_class)
    obj
  end

  describe '#record_mastery' do
    it 'records a success and increases efficacy' do
      result = runner.record_mastery(domain: :coding, outcome_type: :success)
      expect(result[:success]).to be true
      expect(result[:efficacy]).to be > 0.5
    end

    it 'records a failure and decreases efficacy' do
      result = runner.record_mastery(domain: :coding, outcome_type: :failure)
      expect(result[:success]).to be true
      expect(result[:efficacy]).to be < 0.5
    end

    it 'respects attribution level' do
      full = runner.record_mastery(domain: :a, outcome_type: :success, attribution: :full_agency)
      runner2 = Object.new.extend(described_class)
      low = runner2.record_mastery(domain: :a, outcome_type: :success, attribution: :low_agency)
      expect(full[:efficacy]).to be > low[:efficacy]
    end
  end

  describe '#record_vicarious' do
    it 'has weaker effect than mastery' do
      runner.record_mastery(domain: :a, outcome_type: :success)
      mastery_efficacy = runner.efficacy_model.efficacy_for(:a)

      runner2 = Object.new.extend(described_class)
      runner2.record_vicarious(domain: :a, outcome_type: :success)
      vicarious_efficacy = runner2.efficacy_model.efficacy_for(:a)

      expect(mastery_efficacy).to be > vicarious_efficacy
    end
  end

  describe '#record_persuasion' do
    it 'increases efficacy for positive persuasion' do
      result = runner.record_persuasion(domain: :public_speaking, positive: true)
      expect(result[:success]).to be true
      expect(result[:efficacy]).to be > 0.5
    end

    it 'decreases efficacy for negative persuasion' do
      result = runner.record_persuasion(domain: :public_speaking, positive: false)
      expect(result[:efficacy]).to be < 0.5
    end
  end

  describe '#record_physiological' do
    it 'increases efficacy for positive states' do
      result = runner.record_physiological(domain: :exercise, state: :energized)
      expect(result[:success]).to be true
      expect(result[:efficacy]).to be >= 0.5
    end

    it 'decreases efficacy for negative states' do
      result = runner.record_physiological(domain: :exercise, state: :exhausted)
      expect(result[:efficacy]).to be < 0.5
    end
  end

  describe '#update_agency' do
    it 'decays efficacy and returns stats' do
      runner.record_mastery(domain: :coding, outcome_type: :success)
      result = runner.update_agency
      expect(result[:success]).to be true
      expect(result[:stats]).to include(:domain_count, :overall_efficacy)
    end
  end

  describe '#check_efficacy' do
    it 'returns efficacy details for a domain' do
      runner.record_mastery(domain: :coding, outcome_type: :success)
      result = runner.check_efficacy(domain: :coding)
      expect(result[:success]).to be true
      expect(result[:domain]).to eq(:coding)
      expect(result[:label]).to be_a(Symbol)
      expect(result[:success_rate]).to be_a(Float)
    end
  end

  describe '#should_attempt?' do
    it 'recommends attempting when efficacy is above threshold' do
      5.times { runner.record_mastery(domain: :coding, outcome_type: :success) }
      result = runner.should_attempt?(domain: :coding, threshold: 0.3)
      expect(result[:should_attempt]).to be true
    end

    it 'discourages attempting when efficacy is below threshold' do
      5.times { runner.record_mastery(domain: :new_thing, outcome_type: :failure) }
      result = runner.should_attempt?(domain: :new_thing, threshold: 0.5)
      expect(result[:should_attempt]).to be false
    end
  end

  describe '#strongest_domains' do
    it 'returns the highest-efficacy domains' do
      3.times { runner.record_mastery(domain: :strong, outcome_type: :success) }
      runner.record_mastery(domain: :weak, outcome_type: :failure)
      result = runner.strongest_domains(count: 1)
      expect(result[:success]).to be true
      expect(result[:domains].keys.first).to eq(:strong)
    end
  end

  describe '#weakest_domains' do
    it 'returns the lowest-efficacy domains' do
      runner.record_mastery(domain: :strong, outcome_type: :success)
      3.times { runner.record_mastery(domain: :weak, outcome_type: :failure) }
      result = runner.weakest_domains(count: 1)
      expect(result[:domains].keys.first).to eq(:weak)
    end
  end

  describe '#agency_stats' do
    it 'returns overall stats' do
      result = runner.agency_stats
      expect(result[:success]).to be true
      expect(result[:stats]).to include(:domain_count, :overall_efficacy, :history_size, :domains)
    end
  end
end
