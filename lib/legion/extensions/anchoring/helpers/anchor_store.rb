# frozen_string_literal: true

module Legion
  module Extensions
    module Anchoring
      module Helpers
        class AnchorStore
          include Constants

          def initialize
            @anchors    = {} # domain (Symbol) -> Array<Anchor>
            @references = {} # domain (Symbol) -> Float (explicit reference point)
          end

          def add(value:, domain: :general)
            domain = domain.to_sym
            @anchors[domain] ||= []

            anchor = Anchor.new(value: value, domain: domain)
            @anchors[domain] << anchor

            if @anchors[domain].size > Constants::MAX_ANCHORS_PER_DOMAIN
              @anchors[domain] = @anchors[domain].sort_by(&:strength).last(Constants::MAX_ANCHORS_PER_DOMAIN)
            end

            prune_domains
            anchor
          end

          def strongest(domain: :general)
            domain   = domain.to_sym
            anchors  = @anchors[domain]
            return nil if anchors.nil? || anchors.empty?

            anchors.max_by(&:strength)
          end

          def find(id:)
            @anchors.each_value do |arr|
              arr.each { |a| return a if a.id == id }
            end
            nil
          end

          def evaluate(estimate:, domain: :general)
            domain  = domain.to_sym
            anchor  = strongest(domain: domain)
            return { anchored_estimate: estimate.to_f, pull_strength: 0.0, anchor_value: nil, correction: 0.0 } if anchor.nil?

            anchored  = anchor.pull(estimate: estimate)
            pull_str  = anchor.strength * Constants::DEFAULT_ANCHOR_WEIGHT
            correction = estimate.to_f - anchored

            anchor.reinforce(observed_value: estimate)

            {
              anchored_estimate: anchored,
              pull_strength:     pull_str,
              anchor_value:      anchor.value,
              correction:        correction
            }
          end

          def reference_frame(value:, domain: :general)
            domain    = domain.to_sym
            reference = @references[domain] || strongest(domain: domain)&.value
            return { perceived_value: value.to_f, gain_or_loss: :neutral, magnitude: 0.0 } if reference.nil?

            diff       = value.to_f - reference
            gain_loss  = diff >= 0 ? :gain : :loss
            raw_mag    = diff.abs
            magnitude  = gain_loss == :loss ? raw_mag * Constants::LOSS_AVERSION_FACTOR : raw_mag

            { perceived_value: value.to_f, gain_or_loss: gain_loss, magnitude: magnitude, reference: reference, raw_diff: diff }
          end

          def decay_all
            pruned = 0
            @anchors.each_value do |arr|
              arr.each(&:decay)
              before = arr.size
              arr.reject! { |a| a.strength < Constants::ANCHOR_FLOOR }
              pruned += (before - arr.size)
            end
            @anchors.reject! { |_, arr| arr.empty? }
            pruned
          end

          def shift_reference(domain:, new_reference:)
            domain              = domain.to_sym
            old                 = @references[domain]
            @references[domain] = new_reference.to_f

            diff = (new_reference.to_f - old.to_f).abs
            significant = diff >= Constants::REFERENCE_SHIFT_THRESHOLD

            { domain: domain, old_reference: old, new_reference: new_reference.to_f, significant: significant }
          end

          def domains
            @anchors.keys.select { |d| @anchors[d]&.any? }
          end

          def to_h
            total_anchors = @anchors.values.flatten.size
            domain_count  = domains.size

            {
              total_anchors: total_anchors,
              domain_count:  domain_count,
              domains:       domains,
              references:    @references.dup
            }
          end

          private

          def prune_domains
            return unless @anchors.size > Constants::MAX_DOMAINS

            oldest_domain = @anchors.min_by { |_, arr| arr.map(&:last_accessed).min }&.first
            @anchors.delete(oldest_domain) if oldest_domain
          end
        end
      end
    end
  end
end
