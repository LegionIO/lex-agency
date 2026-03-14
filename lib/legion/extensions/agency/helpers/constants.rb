# frozen_string_literal: true

module Legion
  module Extensions
    module Agency
      module Helpers
        module Constants
          # Initial self-efficacy for new domains (moderate confidence)
          DEFAULT_EFFICACY = 0.5

          # EMA alpha for efficacy updates (slow adaptation)
          EFFICACY_ALPHA = 0.12

          # How much mastery success boosts efficacy
          MASTERY_BOOST = 0.15

          # How much failure reduces efficacy (asymmetric — failures hit harder)
          FAILURE_PENALTY = 0.20

          # Vicarious learning multiplier (learning from others' outcomes)
          VICARIOUS_MULTIPLIER = 0.4

          # Verbal persuasion multiplier (being told you can/can't do something)
          PERSUASION_MULTIPLIER = 0.25

          # Physiological state influence on efficacy
          PHYSIOLOGICAL_MULTIPLIER = 0.15

          # Minimum efficacy (never zero — always some belief in possibility)
          EFFICACY_FLOOR = 0.05

          # Maximum efficacy (never perfectly certain)
          EFFICACY_CEILING = 0.98

          # Domain decay rate per tick (unused domains slowly regress toward default)
          DECAY_RATE = 0.002

          # Maximum tracked domains
          MAX_DOMAINS = 100

          # Maximum outcome history per domain
          MAX_HISTORY_PER_DOMAIN = 50

          # Maximum total outcome events
          MAX_TOTAL_HISTORY = 500

          # Sources of efficacy information (Bandura's four sources)
          EFFICACY_SOURCES = %i[mastery vicarious persuasion physiological].freeze

          # Agency attribution levels
          ATTRIBUTION_LEVELS = {
            full_agency:    0.8,
            partial_agency: 0.5,
            low_agency:     0.3,
            no_agency:      0.0
          }.freeze

          # Outcome types
          OUTCOME_TYPES = %i[success failure partial_success unexpected].freeze

          # Efficacy level labels
          EFFICACY_LABELS = {
            (0.8..)     => :highly_capable,
            (0.6...0.8) => :capable,
            (0.4...0.6) => :uncertain,
            (0.2...0.4) => :doubtful,
            (..0.2)     => :helpless
          }.freeze
        end
      end
    end
  end
end
