# frozen_string_literal: true

module Legion
  module Extensions
    module Anchoring
      module Helpers
        module Constants
          DEFAULT_ANCHOR_WEIGHT        = 0.6    # How much the anchor pulls toward itself
          ADJUSTMENT_RATE              = 0.1    # EMA alpha for updating anchors
          ANCHOR_DECAY                 = 0.02   # Per-tick decay of anchor strength
          ANCHOR_FLOOR                 = 0.05   # Minimum anchor strength before pruning
          MAX_ANCHORS_PER_DOMAIN       = 20     # Cap per domain
          MAX_DOMAINS                  = 50     # Cap total domains
          REFERENCE_SHIFT_THRESHOLD    = 0.3    # Gap needed to shift reference point
          LOSS_AVERSION_FACTOR         = 2.25   # Losses weighted 2.25x vs gains (prospect theory)

          ANCHOR_LABELS = {
            (0.8..)     => :strong,
            (0.5...0.8) => :moderate,
            (0.2...0.5) => :weak,
            (..0.2)     => :fading
          }.freeze
        end
      end
    end
  end
end
