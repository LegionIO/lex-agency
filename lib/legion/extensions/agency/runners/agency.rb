# frozen_string_literal: true

module Legion
  module Extensions
    module Agency
      module Runners
        module Agency
          include Legion::Extensions::Helpers::Lex

          def efficacy_model
            @efficacy_model ||= Helpers::EfficacyModel.new
          end

          def record_mastery(domain:, outcome_type:, magnitude: 1.0, attribution: :full_agency, **)
            event = Helpers::OutcomeEvent.new(
              domain: domain, outcome_type: outcome_type, source: :mastery,
              magnitude: magnitude, attribution: attribution
            )
            efficacy_model.record_outcome(event)
            Legion::Logging.debug "[agency] mastery #{outcome_type} in #{domain} " \
                                  "efficacy=#{efficacy_model.efficacy_for(domain).round(4)}"
            { success: true, event: event.to_h, efficacy: efficacy_model.efficacy_for(domain).round(4) }
          end

          def record_vicarious(domain:, outcome_type:, magnitude: 1.0, **)
            event = Helpers::OutcomeEvent.new(
              domain: domain, outcome_type: outcome_type, source: :vicarious,
              magnitude: magnitude, attribution: :partial_agency
            )
            efficacy_model.record_outcome(event)
            Legion::Logging.debug "[agency] vicarious #{outcome_type} in #{domain}"
            { success: true, event: event.to_h, efficacy: efficacy_model.efficacy_for(domain).round(4) }
          end

          def record_persuasion(domain:, positive: true, magnitude: 0.5, **)
            outcome = positive ? :success : :failure
            event = Helpers::OutcomeEvent.new(
              domain: domain, outcome_type: outcome, source: :persuasion,
              magnitude: magnitude, attribution: :partial_agency
            )
            efficacy_model.record_outcome(event)
            Legion::Logging.debug "[agency] persuasion #{positive ? 'positive' : 'negative'} in #{domain}"
            { success: true, event: event.to_h, efficacy: efficacy_model.efficacy_for(domain).round(4) }
          end

          def record_physiological(domain:, state: :energized, **)
            outcome = %i[energized calm focused].include?(state) ? :success : :failure
            magnitude = %i[energized calm focused].include?(state) ? 0.6 : 0.4
            event = Helpers::OutcomeEvent.new(
              domain: domain, outcome_type: outcome, source: :physiological,
              magnitude: magnitude, attribution: :low_agency
            )
            efficacy_model.record_outcome(event)
            Legion::Logging.debug "[agency] physiological #{state} in #{domain}"
            { success: true, event: event.to_h, efficacy: efficacy_model.efficacy_for(domain).round(4) }
          end

          def update_agency(**)
            efficacy_model.decay_all
            Legion::Logging.debug "[agency] tick: domains=#{efficacy_model.domain_count} " \
                                  "overall=#{efficacy_model.overall_efficacy.round(4)}"
            { success: true, stats: efficacy_model.to_h }
          end

          def check_efficacy(domain:, **)
            {
              success:       true,
              domain:        domain,
              efficacy:      efficacy_model.efficacy_for(domain).round(4),
              label:         efficacy_model.efficacy_label(domain),
              success_rate:  efficacy_model.success_rate(domain).round(4),
              history_count: efficacy_model.domain_history(domain).size
            }
          end

          def should_attempt?(domain:, threshold: 0.3, **)
            efficacy = efficacy_model.efficacy_for(domain)
            {
              success:        true,
              domain:         domain,
              efficacy:       efficacy.round(4),
              threshold:      threshold,
              should_attempt: efficacy >= threshold,
              label:          efficacy_model.efficacy_label(domain)
            }
          end

          def strongest_domains(count: 5, **)
            domains = efficacy_model.strongest_domains(count)
            {
              success: true,
              domains: domains.transform_values { |v| v.round(4) },
              count:   domains.size
            }
          end

          def weakest_domains(count: 5, **)
            domains = efficacy_model.weakest_domains(count)
            {
              success: true,
              domains: domains.transform_values { |v| v.round(4) },
              count:   domains.size
            }
          end

          def agency_stats(**)
            { success: true, stats: efficacy_model.to_h }
          end
        end
      end
    end
  end
end
