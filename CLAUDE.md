# lex-anchoring

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Decision anchoring and reference point effects for brain-modeled agentic AI. Models the cognitive bias where initial values (anchors) disproportionately influence subsequent estimates, and implements prospect theory's loss aversion for gain/loss framing around reference points.

## Gem Info

- **Gem name**: `lex-anchoring`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::Anchoring`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/anchoring/
  anchoring.rb           # Main extension module
  version.rb             # VERSION = '0.1.0'
  client.rb              # Client wrapper
  helpers/
    constants.rb         # Weights, decay, loss aversion factor, labels
    anchor.rb            # Anchor value object (strength, pull, decay, reinforce)
    anchor_store.rb      # AnchorStore — per-domain anchor collections + reference points
  runners/
    anchoring.rb         # Runner module with 7 public methods
spec/
  (spec files)
```

## Key Constants

```ruby
DEFAULT_ANCHOR_WEIGHT     = 0.6    # how much the anchor pulls toward itself
ADJUSTMENT_RATE           = 0.1    # EMA alpha for updating anchor value on reinforce
ANCHOR_DECAY              = 0.02   # per-tick strength decay
ANCHOR_FLOOR              = 0.05   # minimum strength before pruning
MAX_ANCHORS_PER_DOMAIN    = 20
MAX_DOMAINS               = 50
REFERENCE_SHIFT_THRESHOLD = 0.3    # gap needed to qualify as a significant reference shift
LOSS_AVERSION_FACTOR      = 2.25   # losses weighted 2.25x vs gains (prospect theory)
ANCHOR_LABELS = { (0.8..) => :strong, (0.5...0.8) => :moderate,
                  (0.2...0.5) => :weak, (..0.2) => :fading }
```

## Runners

### `Runners::Anchoring`

All methods delegate to a private `@anchor_store` (`Helpers::AnchorStore` instance).

- `record_anchor(value:, domain: :general)` — record a new anchor value in a domain
- `evaluate_estimate(estimate:, domain: :general)` — apply the strongest anchor's pull to an estimate; also reinforces the anchor with the observed value
- `reference_frame(value:, domain: :general)` — classify a value as gain or loss relative to the reference point; applies `LOSS_AVERSION_FACTOR` to loss magnitudes
- `de_anchor(estimate:, domain: :general)` — compute the bias introduced by the strongest anchor and return a corrected estimate
- `shift_reference(domain:, new_reference:)` — update the reference point for a domain; flags whether the shift is significant
- `update_anchoring` — decay all anchor strengths, prune below floor
- `domain_anchors(domain:)` — list all anchors in a domain with the strongest highlighted
- `anchoring_stats` — full stats hash

## Helpers

### `Helpers::AnchorStore`
Per-domain `@anchors` hash (domain → Array of Anchor objects) and `@references` hash (domain → Float). `evaluate` calls `anchor.reinforce` with the observed value, updating the anchor's own value via EMA. `prune_domains` evicts the domain with the oldest last-accessed anchor when over `MAX_DOMAINS`.

### `Helpers::Anchor`
Value object. `pull(estimate:)` = `weight * @value + (1 - weight) * estimate` where weight = `strength * DEFAULT_ANCHOR_WEIGHT`. `reinforce` updates value via EMA and increases strength by 0.1. `decay` reduces strength by `ANCHOR_DECAY`.

## Integration Points

No actor defined — callers drive decay via `update_anchoring`. This extension models a bias source; pair it with lex-bias for complete bias detection and correction. `de_anchor` provides explicit bias correction for use in decision-making phases. `reference_frame` feeds into lex-emotion for gain/loss emotional responses.

## Development Notes

- Loss aversion factor of 2.25 is from Kahneman & Tversky's prospect theory empirical measurements
- Reference points can be set explicitly via `shift_reference` or implicitly from the strongest anchor's value
- `evaluate_estimate` has a side effect: it reinforces the anchor with the observed value, slowly updating the anchor toward observed reality
- Per-domain pruning keeps the most recently accessed anchors, evicting oldest when at capacity
