# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agency
      module Helpers
        class OutcomeEvent
          attr_reader :id, :domain, :outcome_type, :source, :magnitude, :attribution, :timestamp

          def initialize(domain:, outcome_type:, source: :mastery, magnitude: 1.0, attribution: :full_agency)
            @id          = SecureRandom.uuid
            @domain      = domain
            @outcome_type = outcome_type
            @source      = source
            @magnitude   = magnitude.clamp(0.0, 1.0)
            @attribution = attribution
            @timestamp   = Time.now.utc
          end

          def success?
            %i[success partial_success].include?(@outcome_type)
          end

          def attributed_magnitude
            level = Constants::ATTRIBUTION_LEVELS[@attribution] || 0.5
            @magnitude * level
          end

          def to_h
            {
              id:                   @id,
              domain:               @domain,
              outcome_type:         @outcome_type,
              source:               @source,
              magnitude:            @magnitude,
              attribution:          @attribution,
              success:              success?,
              attributed_magnitude: attributed_magnitude.round(4),
              timestamp:            @timestamp
            }
          end
        end
      end
    end
  end
end
