# frozen_string_literal: true

module Legion
  module Extensions
    module Agency
      module Helpers
        class EfficacyModel
          attr_reader :domains, :history

          def initialize
            @domains = {}
            @history = []
          end

          def efficacy_for(domain)
            @domains[domain] ||= Constants::DEFAULT_EFFICACY
            @domains[domain]
          end

          def efficacy_label(domain)
            value = efficacy_for(domain)
            Constants::EFFICACY_LABELS.each do |range, label|
              return label if range.cover?(value)
            end
            :uncertain
          end

          def record_outcome(event)
            @history << event
            update_efficacy(event)
            trim_history
            event
          end

          def decay_all
            @domains.each_key do |domain|
              current = @domains[domain]
              diff = Constants::DEFAULT_EFFICACY - current
              @domains[domain] = (current + (diff * Constants::DECAY_RATE)).clamp(
                Constants::EFFICACY_FLOOR, Constants::EFFICACY_CEILING
              )
            end
            trim_domains
          end

          def domain_history(domain)
            @history.select { |e| e.domain == domain }
          end

          def success_rate(domain)
            events = domain_history(domain)
            return 0.0 if events.empty?

            successes = events.count(&:success?)
            successes.to_f / events.size
          end

          def strongest_domains(count = 5)
            @domains.sort_by { |_, v| -v }.first(count).to_h
          end

          def weakest_domains(count = 5)
            @domains.sort_by { |_, v| v }.first(count).to_h
          end

          def overall_efficacy
            return Constants::DEFAULT_EFFICACY if @domains.empty?

            @domains.values.sum / @domains.size
          end

          def domain_count
            @domains.size
          end

          def to_h
            {
              domain_count:     @domains.size,
              overall_efficacy: overall_efficacy.round(4),
              history_size:     @history.size,
              domains:          @domains.transform_values { |v| v.round(4) }
            }
          end

          private

          def update_efficacy(event)
            domain = event.domain
            current = efficacy_for(domain)
            delta = compute_delta(event)

            new_value = current + (Constants::EFFICACY_ALPHA * delta)
            @domains[domain] = new_value.clamp(Constants::EFFICACY_FLOOR, Constants::EFFICACY_CEILING)
          end

          def compute_delta(event)
            base = event.attributed_magnitude
            multiplier = source_multiplier(event.source)

            if event.success?
              base * multiplier * Constants::MASTERY_BOOST / Constants::EFFICACY_ALPHA
            else
              -base * multiplier * Constants::FAILURE_PENALTY / Constants::EFFICACY_ALPHA
            end
          end

          def source_multiplier(source)
            case source
            when :mastery       then 1.0
            when :vicarious     then Constants::VICARIOUS_MULTIPLIER
            when :persuasion    then Constants::PERSUASION_MULTIPLIER
            when :physiological then Constants::PHYSIOLOGICAL_MULTIPLIER
            else 0.5
            end
          end

          def trim_history
            @history.shift(@history.size - Constants::MAX_TOTAL_HISTORY) if @history.size > Constants::MAX_TOTAL_HISTORY
          end

          def trim_domains
            return unless @domains.size > Constants::MAX_DOMAINS

            sorted = @domains.sort_by { |_, v| (v - Constants::DEFAULT_EFFICACY).abs }
            excess = @domains.size - Constants::MAX_DOMAINS
            sorted.first(excess).each { |domain, _| @domains.delete(domain) } # rubocop:disable Style/HashEachMethods
          end
        end
      end
    end
  end
end
