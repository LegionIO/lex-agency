# lex-agency

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Implements Bandura's self-efficacy theory for LegionIO agents — tracks belief in ability to achieve outcomes across domains, mastery experiences, vicarious learning, and agency attribution. Models how agents build and maintain confidence in their own capabilities through four distinct information sources.

## Gem Info

- **Gem name**: `lex-agency`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::Agency`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/agency/
  agency.rb               # Main extension module
  version.rb              # VERSION = '0.1.0'
  client.rb               # Client wrapper
  helpers/
    constants.rb          # Efficacy bounds, decay, multipliers, labels
    outcome_event.rb      # OutcomeEvent value object
    efficacy_model.rb     # EfficacyModel — domain-level efficacy tracking
  runners/
    agency.rb             # Runner module with 9 public methods
spec/
  (spec files)
```

## Key Constants

```ruby
DEFAULT_EFFICACY     = 0.5
EFFICACY_ALPHA       = 0.12   # EMA alpha for efficacy updates
MASTERY_BOOST        = 0.15   # success boost multiplier
FAILURE_PENALTY      = 0.20   # failure penalty (asymmetric — failures hit harder)
VICARIOUS_MULTIPLIER = 0.4    # learning from others' outcomes
PERSUASION_MULTIPLIER = 0.25  # being told you can/can't
PHYSIOLOGICAL_MULTIPLIER = 0.15
EFFICACY_FLOOR       = 0.05   # never zero
EFFICACY_CEILING     = 0.98   # never perfectly certain
DECAY_RATE           = 0.002  # unused domains regress toward default per tick
MAX_DOMAINS          = 100
MAX_HISTORY_PER_DOMAIN = 50
MAX_TOTAL_HISTORY    = 500
EFFICACY_SOURCES     = %i[mastery vicarious persuasion physiological]
ATTRIBUTION_LEVELS   = { full_agency: 0.8, partial_agency: 0.5, low_agency: 0.3, no_agency: 0.0 }
OUTCOME_TYPES        = %i[success failure partial_success unexpected]
EFFICACY_LABELS      = { (0.8..) => :highly_capable, ... (..0.2) => :helpless }
```

## Runners

### `Runners::Agency`

All methods delegate to a private `@efficacy_model` (`Helpers::EfficacyModel` instance).

- `record_mastery(domain:, outcome_type:, magnitude: 1.0, attribution: :full_agency)` — record direct experience outcome; highest impact source
- `record_vicarious(domain:, outcome_type:, magnitude: 1.0)` — record learning from observing others; 0.4x multiplier
- `record_persuasion(domain:, positive: true, magnitude: 0.5)` — record verbal persuasion (being told you can/can't); 0.25x multiplier
- `record_physiological(domain:, state: :energized)` — record physiological state influence; 0.15x multiplier
- `update_agency` — decay all domain efficacies toward default (call periodically)
- `check_efficacy(domain:)` — returns current efficacy, label, success rate, and history count
- `should_attempt?(domain:, threshold: 0.3)` — decision gate: returns `should_attempt: bool` based on efficacy vs threshold
- `strongest_domains(count: 5)` — top domains by efficacy
- `weakest_domains(count: 5)` — bottom domains by efficacy
- `agency_stats` — full stats hash

## Helpers

### `Helpers::EfficacyModel`
EMA-based domain efficacy tracker. `compute_delta` applies source multipliers to scale the impact of each outcome type. Decay slowly regresses unused domains toward `DEFAULT_EFFICACY`. Trims to `MAX_DOMAINS` by removing domains closest to default when over capacity.

### `Helpers::OutcomeEvent`
Value object recording domain, outcome_type, source, magnitude, attribution, and timestamp. `attributed_magnitude` = `magnitude * ATTRIBUTION_LEVELS[attribution]`, scaling impact by how much the agent believes it caused the outcome.

## Integration Points

No actor defined — callers must invoke `update_agency` for decay. Integrates naturally into lex-tick's `action_selection` phase via `should_attempt?` to gate whether the agent attempts actions in specific domains. `record_mastery` should be called after task outcomes to build accurate domain-level confidence.

## Development Notes

- Delta computation: `base * multiplier * MASTERY_BOOST / EFFICACY_ALPHA` for successes, negative equivalent for failures. The division by `EFFICACY_ALPHA` normalizes the delta relative to the EMA window
- `partial_success` is treated as success for efficacy purposes
- `physiological` state mapping: `:energized`, `:calm`, `:focused` → success; others → failure
- Asymmetry: `FAILURE_PENALTY (0.20) > MASTERY_BOOST (0.15)` models the well-documented negativity bias
