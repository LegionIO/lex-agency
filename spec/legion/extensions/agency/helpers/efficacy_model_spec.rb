# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Agency::Helpers::EfficacyModel do
  subject(:model) { described_class.new }

  let(:constants) { Legion::Extensions::Agency::Helpers::Constants }

  describe '#initialize' do
    it 'starts with empty domains' do
      expect(model.domains).to eq({})
    end

    it 'starts with empty history' do
      expect(model.history).to eq([])
    end
  end

  describe '#efficacy_for' do
    it 'returns default for unknown domains' do
      expect(model.efficacy_for(:coding)).to eq(constants::DEFAULT_EFFICACY)
    end

    it 'initializes the domain on first access' do
      model.efficacy_for(:coding)
      expect(model.domains).to have_key(:coding)
    end
  end

  describe '#efficacy_label' do
    it 'returns :uncertain for default efficacy' do
      expect(model.efficacy_label(:new_domain)).to eq(:uncertain)
    end
  end

  describe '#record_outcome' do
    it 'records a success event and increases efficacy' do
      initial = model.efficacy_for(:coding)
      event = Legion::Extensions::Agency::Helpers::OutcomeEvent.new(domain: :coding, outcome_type: :success)
      model.record_outcome(event)
      expect(model.efficacy_for(:coding)).to be > initial
    end

    it 'records a failure event and decreases efficacy' do
      initial = model.efficacy_for(:coding)
      event = Legion::Extensions::Agency::Helpers::OutcomeEvent.new(domain: :coding, outcome_type: :failure)
      model.record_outcome(event)
      expect(model.efficacy_for(:coding)).to be < initial
    end

    it 'clamps efficacy within bounds' do
      20.times do
        event = Legion::Extensions::Agency::Helpers::OutcomeEvent.new(domain: :x, outcome_type: :success)
        model.record_outcome(event)
      end
      expect(model.efficacy_for(:x)).to be <= constants::EFFICACY_CEILING

      20.times do
        event = Legion::Extensions::Agency::Helpers::OutcomeEvent.new(domain: :y, outcome_type: :failure)
        model.record_outcome(event)
      end
      expect(model.efficacy_for(:y)).to be >= constants::EFFICACY_FLOOR
    end

    it 'applies vicarious multiplier' do
      mastery = Legion::Extensions::Agency::Helpers::OutcomeEvent.new(domain: :a, outcome_type: :success, source: :mastery)
      vicarious = Legion::Extensions::Agency::Helpers::OutcomeEvent.new(domain: :b, outcome_type: :success, source: :vicarious)

      model.record_outcome(mastery)
      model.record_outcome(vicarious)

      # Mastery should have stronger effect than vicarious
      expect(model.efficacy_for(:a)).to be > model.efficacy_for(:b)
    end

    it 'applies persuasion multiplier' do
      event = Legion::Extensions::Agency::Helpers::OutcomeEvent.new(domain: :coding, outcome_type: :success, source: :persuasion)
      initial = model.efficacy_for(:coding)
      model.record_outcome(event)
      # Persuasion has weaker effect than mastery
      delta_persuasion = model.efficacy_for(:coding) - initial

      model2 = described_class.new
      mastery = Legion::Extensions::Agency::Helpers::OutcomeEvent.new(domain: :coding, outcome_type: :success, source: :mastery)
      initial2 = model2.efficacy_for(:coding)
      model2.record_outcome(mastery)
      delta_mastery = model2.efficacy_for(:coding) - initial2

      expect(delta_mastery).to be > delta_persuasion
    end

    it 'stores event in history' do
      event = Legion::Extensions::Agency::Helpers::OutcomeEvent.new(domain: :coding, outcome_type: :success)
      model.record_outcome(event)
      expect(model.history.size).to eq(1)
    end

    it 'trims history at MAX_TOTAL_HISTORY' do
      (constants::MAX_TOTAL_HISTORY + 10).times do
        event = Legion::Extensions::Agency::Helpers::OutcomeEvent.new(domain: :coding, outcome_type: :success)
        model.record_outcome(event)
      end
      expect(model.history.size).to eq(constants::MAX_TOTAL_HISTORY)
    end
  end

  describe '#decay_all' do
    it 'moves efficacy toward default' do
      event = Legion::Extensions::Agency::Helpers::OutcomeEvent.new(domain: :coding, outcome_type: :success)
      5.times { model.record_outcome(event) }
      high = model.efficacy_for(:coding)

      model.decay_all
      expect(model.efficacy_for(:coding)).to be < high
    end

    it 'trims excess domains' do
      (constants::MAX_DOMAINS + 5).times do |i|
        model.efficacy_for(:"domain_#{i}")
      end
      model.decay_all
      expect(model.domain_count).to be <= constants::MAX_DOMAINS
    end
  end

  describe '#domain_history' do
    it 'filters history by domain' do
      event_a = Legion::Extensions::Agency::Helpers::OutcomeEvent.new(domain: :a, outcome_type: :success)
      event_b = Legion::Extensions::Agency::Helpers::OutcomeEvent.new(domain: :b, outcome_type: :failure)
      model.record_outcome(event_a)
      model.record_outcome(event_b)
      expect(model.domain_history(:a).size).to eq(1)
    end
  end

  describe '#success_rate' do
    it 'returns 0 for empty domain' do
      expect(model.success_rate(:empty)).to eq(0.0)
    end

    it 'computes correct rate' do
      3.times do
        event = Legion::Extensions::Agency::Helpers::OutcomeEvent.new(domain: :x, outcome_type: :success)
        model.record_outcome(event)
      end
      event = Legion::Extensions::Agency::Helpers::OutcomeEvent.new(domain: :x, outcome_type: :failure)
      model.record_outcome(event)
      expect(model.success_rate(:x)).to eq(0.75)
    end
  end

  describe '#strongest_domains / #weakest_domains' do
    before do
      model.record_outcome(Legion::Extensions::Agency::Helpers::OutcomeEvent.new(domain: :strong, outcome_type: :success))
      model.record_outcome(Legion::Extensions::Agency::Helpers::OutcomeEvent.new(domain: :strong, outcome_type: :success))
      model.record_outcome(Legion::Extensions::Agency::Helpers::OutcomeEvent.new(domain: :weak, outcome_type: :failure))
      model.record_outcome(Legion::Extensions::Agency::Helpers::OutcomeEvent.new(domain: :weak, outcome_type: :failure))
    end

    it 'returns strongest domains first' do
      top = model.strongest_domains(1)
      expect(top.keys.first).to eq(:strong)
    end

    it 'returns weakest domains first' do
      bottom = model.weakest_domains(1)
      expect(bottom.keys.first).to eq(:weak)
    end
  end

  describe '#overall_efficacy' do
    it 'returns default when empty' do
      expect(model.overall_efficacy).to eq(constants::DEFAULT_EFFICACY)
    end

    it 'returns average across domains' do
      model.efficacy_for(:a)
      model.efficacy_for(:b)
      expect(model.overall_efficacy).to eq(constants::DEFAULT_EFFICACY)
    end
  end

  describe '#to_h' do
    it 'returns a snapshot hash' do
      h = model.to_h
      expect(h).to include(:domain_count, :overall_efficacy, :history_size, :domains)
    end
  end
end
