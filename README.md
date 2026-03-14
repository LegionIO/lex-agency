# lex-agency

Self-efficacy and agency modeling for LegionIO — implements Bandura's self-efficacy theory for agentic AI.

## What It Does

Tracks the agent's belief in its own ability to achieve outcomes across different domains. Uses Bandura's four sources of self-efficacy: mastery experiences (direct outcomes), vicarious learning (observing others), verbal persuasion (being told you can/can't), and physiological states. Efficacy scores determine whether the agent should attempt tasks and are used to prioritize domain engagement.

## Core Concept: Domain-Level Self-Efficacy

Each domain maintains an efficacy score (0.05–0.98) updated via EMA when outcomes are recorded. Failures hit harder than successes (asymmetric update):

```ruby
# Direct mastery experience has the highest impact
client.record_mastery(domain: :terraform, outcome_type: :success, magnitude: 1.0)

# Learning from others has 0.4x the impact
client.record_vicarious(domain: :kubernetes, outcome_type: :success)

# Gate whether to attempt an action
result = client.should_attempt?(domain: :terraform, threshold: 0.3)
# => { should_attempt: true, efficacy: 0.72, label: :capable }
```

## Usage

```ruby
client = Legion::Extensions::Agency::Client.new

# Record outcomes from all four sources
client.record_mastery(domain: :networking, outcome_type: :failure, attribution: :full_agency)
client.record_vicarious(domain: :security, outcome_type: :success, magnitude: 0.8)
client.record_persuasion(domain: :ml, positive: true, magnitude: 0.6)
client.record_physiological(domain: :reasoning, state: :energized)

# Query efficacy
client.check_efficacy(domain: :networking)
# => { efficacy: 0.38, label: :doubtful, success_rate: 0.2, history_count: 3 }

# Find strongest and weakest domains
client.strongest_domains(count: 3)
client.weakest_domains(count: 3)

# Maintenance (decay unused domains toward default)
client.update_agency
```

## Integration

Wire `should_attempt?` into lex-tick's `action_selection` phase to prevent the agent from attempting tasks in domains where it has learned it is ineffective. Call `record_mastery` after task completion to build accurate per-domain confidence over time.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
