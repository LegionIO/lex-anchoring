# frozen_string_literal: true

module Legion
  module Extensions
    module Anchoring
      module Runners
        module Anchoring
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def record_anchor(value:, domain: :general, **)
            anchor = anchor_store.add(value: value, domain: domain)
            Legion::Logging.debug "[anchoring] record_anchor domain=#{domain} value=#{value} id=#{anchor.id}"
            { success: true, anchor: anchor.to_h }
          end

          def evaluate_estimate(estimate:, domain: :general, **)
            result = anchor_store.evaluate(estimate: estimate, domain: domain)
            Legion::Logging.debug "[anchoring] evaluate_estimate domain=#{domain} estimate=#{estimate} " \
                                  "anchored=#{result[:anchored_estimate].round(4)} pull=#{result[:pull_strength].round(4)}"
            { success: true }.merge(result)
          end

          def reference_frame(value:, domain: :general, **)
            result = anchor_store.reference_frame(value: value, domain: domain)
            Legion::Logging.debug "[anchoring] reference_frame domain=#{domain} value=#{value} " \
                                  "gain_or_loss=#{result[:gain_or_loss]}"
            { success: true }.merge(result)
          end

          def de_anchor(estimate:, domain: :general, **)
            anchor = anchor_store.strongest(domain: domain)
            if anchor.nil?
              Legion::Logging.debug "[anchoring] de_anchor domain=#{domain} no anchor found"
              return { success: true, corrected_estimate: estimate.to_f, anchor_bias: 0.0, domain: domain }
            end

            biased    = anchor.pull(estimate: estimate)
            bias      = biased - estimate.to_f
            corrected = estimate.to_f - bias

            Legion::Logging.debug "[anchoring] de_anchor domain=#{domain} estimate=#{estimate} " \
                                  "corrected=#{corrected.round(4)} bias=#{bias.round(4)}"

            {
              success:            true,
              corrected_estimate: corrected,
              original_estimate:  estimate.to_f,
              anchor_bias:        bias,
              anchor_value:       anchor.value,
              domain:             domain
            }
          end

          def shift_reference(domain:, new_reference:, **)
            result = anchor_store.shift_reference(domain: domain, new_reference: new_reference)
            Legion::Logging.info "[anchoring] shift_reference domain=#{domain} new=#{new_reference} significant=#{result[:significant]}"
            { success: true }.merge(result)
          end

          def update_anchoring(**)
            pruned = anchor_store.decay_all
            Legion::Logging.debug "[anchoring] update_anchoring pruned=#{pruned}"
            { success: true, pruned: pruned }
          end

          def domain_anchors(domain:, **)
            domain   = domain.to_sym
            anchor   = anchor_store.strongest(domain: domain)
            all_list = anchor_store.instance_variable_get(:@anchors)[domain] || []
            Legion::Logging.debug "[anchoring] domain_anchors domain=#{domain} count=#{all_list.size}"
            {
              success:   true,
              domain:    domain,
              count:     all_list.size,
              strongest: anchor&.to_h,
              anchors:   all_list.map(&:to_h)
            }
          end

          def anchoring_stats(**)
            stats = anchor_store.to_h
            Legion::Logging.debug "[anchoring] stats domains=#{stats[:domain_count]} total=#{stats[:total_anchors]}"
            { success: true }.merge(stats)
          end

          private

          def anchor_store
            @anchor_store ||= Helpers::AnchorStore.new
          end
        end
      end
    end
  end
end
