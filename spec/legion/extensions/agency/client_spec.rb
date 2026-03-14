# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Agency::Client do
  subject(:client) { described_class.new }

  describe '#initialize' do
    it 'creates a default efficacy model' do
      expect(client.efficacy_model).to be_a(Legion::Extensions::Agency::Helpers::EfficacyModel)
    end

    it 'accepts an injected model' do
      custom = Legion::Extensions::Agency::Helpers::EfficacyModel.new
      injected = described_class.new(efficacy_model: custom)
      expect(injected.efficacy_model).to equal(custom)
    end
  end

  describe 'Bandura self-efficacy lifecycle' do
    it 'models the four sources of self-efficacy and their relative strengths' do
      # Source 1: Mastery experience (strongest source)
      client.record_mastery(domain: :coding, outcome_type: :success)
      client.record_mastery(domain: :coding, outcome_type: :success)
      coding_after_mastery = client.efficacy_model.efficacy_for(:coding)
      expect(coding_after_mastery).to be > 0.5

      # Source 2: Vicarious experience (weaker than mastery)
      client.record_vicarious(domain: :public_speaking, outcome_type: :success)
      speaking_after_vicarious = client.efficacy_model.efficacy_for(:public_speaking)
      expect(speaking_after_vicarious).to be > 0.5
      expect(speaking_after_vicarious).to be < coding_after_mastery

      # Source 3: Verbal persuasion (weakest cognitive source)
      client.record_persuasion(domain: :management, positive: true)
      mgmt = client.efficacy_model.efficacy_for(:management)
      expect(mgmt).to be > 0.5

      # Source 4: Physiological state
      client.record_physiological(domain: :exercise, state: :energized)
      exercise = client.efficacy_model.efficacy_for(:exercise)
      expect(exercise).to be >= 0.5

      # Check overall stats
      stats = client.agency_stats
      expect(stats[:stats][:domain_count]).to eq(4)

      # Decision gate: should attempt based on efficacy
      coding_decision = client.should_attempt?(domain: :coding, threshold: 0.4)
      expect(coding_decision[:should_attempt]).to be true

      # Strongest domains should be coding (most mastery experiences)
      strongest = client.strongest_domains(count: 1)
      expect(strongest[:domains].keys.first).to eq(:coding)

      # Now model failure — repeated failures erode self-efficacy
      5.times { client.record_mastery(domain: :sales, outcome_type: :failure) }
      sales_check = client.check_efficacy(domain: :sales)
      expect(sales_check[:label]).to eq(:helpless).or eq(:doubtful)

      # Decay over time moves everything slowly toward default
      10.times { client.update_agency }
      coding_after_decay = client.efficacy_model.efficacy_for(:coding)
      expect(coding_after_decay).to be < coding_after_mastery
    end
  end
end
