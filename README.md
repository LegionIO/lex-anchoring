# lex-anchoring

Decision anchoring and reference point effects for brain-modeled agentic AI.

## What It Does

Models the cognitive anchoring bias: initial values exert disproportionate gravitational pull on subsequent estimates. Implements both anchoring (estimates are pulled toward initial values) and prospect theory's reference point framing (outcomes are perceived as gains or losses relative to a reference, with losses weighted 2.25x more than equivalent gains).

## Core Concept: Anchor Pull

An anchor exerts a pull on estimates proportional to its strength:

```ruby
# anchored_estimate = (strength * DEFAULT_ANCHOR_WEIGHT * anchor_value) +
#                     ((1 - strength * DEFAULT_ANCHOR_WEIGHT) * raw_estimate)
```

With default weight 0.6 and full strength, a strong anchor pulls 60% toward itself.

## Usage

```ruby
client = Legion::Extensions::Anchoring::Client.new

# Record an anchor (e.g., initial budget estimate)
client.record_anchor(value: 100_000.0, domain: :budget)

# Evaluate a new estimate — it will be pulled toward the anchor
result = client.evaluate_estimate(estimate: 150_000.0, domain: :budget)
# => { anchored_estimate: 130_000.0, pull_strength: 0.6, correction: 20_000.0 }

# Frame a value as gain or loss (with 2.25x loss aversion)
client.reference_frame(value: 80_000.0, domain: :budget)
# => { gain_or_loss: :loss, magnitude: 45_000.0, reference: 100_000.0 }

# Remove the bias to get the corrected estimate
client.de_anchor(estimate: 130_000.0, domain: :budget)
# => { corrected_estimate: 110_000.0, anchor_bias: 20_000.0 }

# Maintenance
client.update_anchoring
```

## Integration

Pairs with lex-bias for comprehensive bias detection. `reference_frame` output feeds naturally into lex-emotion for emotional gain/loss responses. Wire into decision phases where the agent evaluates numerical estimates or compares outcomes against baselines.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
