# frozen_string_literal: true

require 'legion/extensions/anchoring/client'

RSpec.describe Legion::Extensions::Anchoring::Runners::Anchoring do
  let(:client) { Legion::Extensions::Anchoring::Client.new }

  describe '#record_anchor' do
    it 'returns success: true' do
      result = client.record_anchor(value: 100.0, domain: :financial)
      expect(result[:success]).to be true
    end

    it 'returns anchor hash' do
      result = client.record_anchor(value: 100.0, domain: :financial)
      expect(result[:anchor]).to include(:id, :value, :domain, :strength)
    end

    it 'uses :general domain by default' do
      result = client.record_anchor(value: 50.0)
      expect(result[:anchor][:domain]).to eq(:general)
    end

    it 'accepts keyword splat' do
      expect { client.record_anchor(value: 10.0, extra: :ignored) }.not_to raise_error
    end
  end

  describe '#evaluate_estimate' do
    it 'returns success: true' do
      result = client.evaluate_estimate(estimate: 100.0, domain: :financial)
      expect(result[:success]).to be true
    end

    it 'returns no-pull when domain has no anchors' do
      result = client.evaluate_estimate(estimate: 100.0, domain: :noanchor)
      expect(result[:pull_strength]).to eq(0.0)
      expect(result[:anchored_estimate]).to eq(100.0)
    end

    it 'biases estimate toward anchor when anchor exists' do
      client.record_anchor(value: 50.0, domain: :financial)
      result = client.evaluate_estimate(estimate: 100.0, domain: :financial)
      expect(result[:anchored_estimate]).to be < 100.0
      expect(result[:anchored_estimate]).to be > 50.0
    end

    it 'includes pull_strength, anchor_value, correction' do
      client.record_anchor(value: 50.0, domain: :financial)
      result = client.evaluate_estimate(estimate: 100.0, domain: :financial)
      expect(result).to include(:pull_strength, :anchor_value, :correction)
    end
  end

  describe '#reference_frame' do
    it 'returns success: true' do
      result = client.reference_frame(value: 100.0, domain: :financial)
      expect(result[:success]).to be true
    end

    it 'returns neutral for domain without reference' do
      result = client.reference_frame(value: 100.0, domain: :empty_domain)
      expect(result[:gain_or_loss]).to eq(:neutral)
    end

    it 'detects gain after setting reference' do
      client.shift_reference(domain: :financial, new_reference: 50.0)
      result = client.reference_frame(value: 100.0, domain: :financial)
      expect(result[:gain_or_loss]).to eq(:gain)
    end

    it 'detects loss after setting reference' do
      client.shift_reference(domain: :financial, new_reference: 100.0)
      result = client.reference_frame(value: 50.0, domain: :financial)
      expect(result[:gain_or_loss]).to eq(:loss)
    end

    it 'applies loss aversion factor to losses' do
      client.shift_reference(domain: :financial, new_reference: 100.0)
      result = client.reference_frame(value: 50.0, domain: :financial)
      expect(result[:magnitude]).to be_within(0.001).of(50.0 * 2.25)
    end
  end

  describe '#de_anchor' do
    it 'returns success: true' do
      result = client.de_anchor(estimate: 100.0, domain: :empty_de)
      expect(result[:success]).to be true
    end

    it 'returns original estimate with zero bias when no anchor' do
      result = client.de_anchor(estimate: 100.0, domain: :no_anchor_domain)
      expect(result[:corrected_estimate]).to eq(100.0)
      expect(result[:anchor_bias]).to eq(0.0)
    end

    it 'returns corrected estimate that removes anchor bias' do
      client.record_anchor(value: 50.0, domain: :financial)
      result = client.de_anchor(estimate: 100.0, domain: :financial)
      expect(result[:corrected_estimate]).to be > 100.0
    end

    it 'returns anchor_value when anchor present' do
      client.record_anchor(value: 50.0, domain: :financial)
      result = client.de_anchor(estimate: 100.0, domain: :financial)
      expect(result[:anchor_value]).to eq(50.0)
    end

    it 'includes original_estimate' do
      client.record_anchor(value: 50.0, domain: :financial)
      result = client.de_anchor(estimate: 100.0, domain: :financial)
      expect(result[:original_estimate]).to eq(100.0)
    end
  end

  describe '#shift_reference' do
    it 'returns success: true' do
      result = client.shift_reference(domain: :financial, new_reference: 100.0)
      expect(result[:success]).to be true
    end

    it 'includes domain, old_reference, new_reference, significant' do
      result = client.shift_reference(domain: :financial, new_reference: 100.0)
      expect(result).to include(:domain, :old_reference, :new_reference, :significant)
    end

    it 'marks large shift as significant' do
      client.shift_reference(domain: :financial, new_reference: 0.0)
      result = client.shift_reference(domain: :financial, new_reference: 1.0)
      expect(result[:significant]).to be true
    end
  end

  describe '#update_anchoring' do
    it 'returns success: true' do
      result = client.update_anchoring
      expect(result[:success]).to be true
    end

    it 'returns pruned count' do
      result = client.update_anchoring
      expect(result).to have_key(:pruned)
    end

    it 'decays existing anchors' do
      client.record_anchor(value: 100.0, domain: :financial)
      anchor = client.anchor_store.strongest(domain: :financial)
      before_strength = anchor.strength
      client.update_anchoring
      expect(anchor.strength).to be < before_strength
    end
  end

  describe '#domain_anchors' do
    it 'returns success: true' do
      result = client.domain_anchors(domain: :financial)
      expect(result[:success]).to be true
    end

    it 'returns empty anchors for unknown domain' do
      result = client.domain_anchors(domain: :no_such_domain)
      expect(result[:count]).to eq(0)
      expect(result[:anchors]).to eq([])
    end

    it 'returns anchors for known domain' do
      client.record_anchor(value: 100.0, domain: :financial)
      result = client.domain_anchors(domain: :financial)
      expect(result[:count]).to eq(1)
      expect(result[:anchors].first[:value]).to eq(100.0)
    end

    it 'includes strongest anchor' do
      client.record_anchor(value: 100.0, domain: :financial)
      result = client.domain_anchors(domain: :financial)
      expect(result[:strongest]).not_to be_nil
    end
  end

  describe '#anchoring_stats' do
    it 'returns success: true' do
      result = client.anchoring_stats
      expect(result[:success]).to be true
    end

    it 'includes total_anchors, domain_count, domains' do
      result = client.anchoring_stats
      expect(result).to include(:total_anchors, :domain_count, :domains)
    end

    it 'reflects anchor counts' do
      client.record_anchor(value: 10.0, domain: :financial)
      client.record_anchor(value: 20.0, domain: :temporal)
      result = client.anchoring_stats
      expect(result[:total_anchors]).to eq(2)
      expect(result[:domain_count]).to eq(2)
    end
  end
end
