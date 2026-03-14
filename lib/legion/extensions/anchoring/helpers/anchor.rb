# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Anchoring
      module Helpers
        class Anchor
          include Constants

          attr_reader :id, :value, :domain, :strength, :created_at, :last_accessed

          def initialize(value:, domain: :general)
            @id            = SecureRandom.uuid
            @value         = value.to_f
            @domain        = domain.to_sym
            @strength      = 1.0
            @created_at    = Time.now.utc
            @last_accessed = Time.now.utc
          end

          def decay
            @strength = [(@strength - Constants::ANCHOR_DECAY), 0.0].max
          end

          def reinforce(observed_value:)
            @last_accessed = Time.now.utc
            alpha          = Constants::ADJUSTMENT_RATE
            @value         = ((1.0 - alpha) * @value) + (alpha * observed_value.to_f)
            @strength      = [@strength + 0.1, 1.0].min
          end

          def pull(estimate:)
            weight = @strength * Constants::DEFAULT_ANCHOR_WEIGHT
            (weight * @value) + ((1.0 - weight) * estimate.to_f)
          end

          def label
            Constants::ANCHOR_LABELS.each do |range, lbl|
              return lbl if range.cover?(@strength)
            end
            :fading
          end

          def to_h
            {
              id:            @id,
              value:         @value,
              domain:        @domain,
              strength:      @strength,
              label:         label,
              created_at:    @created_at,
              last_accessed: @last_accessed
            }
          end
        end
      end
    end
  end
end
