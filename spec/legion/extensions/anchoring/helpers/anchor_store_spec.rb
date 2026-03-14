# frozen_string_literal: true

RSpec.describe Legion::Extensions::Anchoring::Helpers::AnchorStore do
  subject(:store) { described_class.new }

  describe '#add' do
    it 'creates and returns an Anchor' do
      anchor = store.add(value: 50.0, domain: :financial)
      expect(anchor).to be_a(Legion::Extensions::Anchoring::Helpers::Anchor)
    end

    it 'stores anchors per domain' do
      store.add(value: 50.0, domain: :financial)
      store.add(value: 80.0, domain: :financial)
      store.add(value: 10.0, domain: :temporal)
      expect(store.domains).to include(:financial, :temporal)
    end

    it 'enforces MAX_ANCHORS_PER_DOMAIN limit' do
      max = Legion::Extensions::Anchoring::Helpers::Constants::MAX_ANCHORS_PER_DOMAIN
      (max + 5).times { |i| store.add(value: i.to_f, domain: :financial) }
      all = store.instance_variable_get(:@anchors)[:financial]
      expect(all.size).to be <= max
    end

    it 'accepts integer value' do
      anchor = store.add(value: 100, domain: :general)
      expect(anchor.value).to eq(100.0)
    end
  end

  describe '#strongest' do
    it 'returns nil for unknown domain' do
      expect(store.strongest(domain: :unknown)).to be_nil
    end

    it 'returns the anchor with highest strength' do
      a1 = store.add(value: 10.0, domain: :financial)
      a2 = store.add(value: 20.0, domain: :financial)
      a1.instance_variable_set(:@strength, 0.3)
      a2.instance_variable_set(:@strength, 0.9)
      expect(store.strongest(domain: :financial).value).to eq(20.0)
    end
  end

  describe '#find' do
    it 'finds anchor by id' do
      anchor = store.add(value: 42.0, domain: :general)
      found  = store.find(id: anchor.id)
      expect(found).to eq(anchor)
    end

    it 'returns nil for unknown id' do
      expect(store.find(id: 'nonexistent')).to be_nil
    end
  end

  describe '#evaluate' do
    it 'returns no-pull result when domain has no anchors' do
      result = store.evaluate(estimate: 100.0, domain: :empty)
      expect(result[:pull_strength]).to eq(0.0)
      expect(result[:anchored_estimate]).to eq(100.0)
      expect(result[:anchor_value]).to be_nil
    end

    it 'returns biased estimate when anchor exists' do
      store.add(value: 50.0, domain: :financial)
      result = store.evaluate(estimate: 100.0, domain: :financial)
      expect(result[:anchored_estimate]).to be > 50.0
      expect(result[:anchored_estimate]).to be < 100.0
    end

    it 'includes pull_strength, anchor_value, correction keys' do
      store.add(value: 50.0, domain: :financial)
      result = store.evaluate(estimate: 100.0, domain: :financial)
      expect(result).to include(:pull_strength, :anchor_value, :correction)
    end

    it 'correction is estimate minus anchored_estimate' do
      store.add(value: 50.0, domain: :financial)
      result = store.evaluate(estimate: 100.0, domain: :financial)
      expect(result[:correction]).to be_within(0.001).of(100.0 - result[:anchored_estimate])
    end
  end

  describe '#reference_frame' do
    it 'returns neutral when no reference or anchor' do
      result = store.reference_frame(value: 100.0, domain: :empty)
      expect(result[:gain_or_loss]).to eq(:neutral)
      expect(result[:magnitude]).to eq(0.0)
    end

    it 'detects gain when value above reference' do
      store.shift_reference(domain: :financial, new_reference: 50.0)
      result = store.reference_frame(value: 100.0, domain: :financial)
      expect(result[:gain_or_loss]).to eq(:gain)
      expect(result[:magnitude]).to be > 0
    end

    it 'detects loss when value below reference' do
      store.shift_reference(domain: :financial, new_reference: 100.0)
      result = store.reference_frame(value: 50.0, domain: :financial)
      expect(result[:gain_or_loss]).to eq(:loss)
    end

    it 'applies loss aversion factor to losses' do
      store.shift_reference(domain: :financial, new_reference: 100.0)
      result = store.reference_frame(value: 50.0, domain: :financial)
      raw_diff = 50.0
      expected_magnitude = raw_diff * Legion::Extensions::Anchoring::Helpers::Constants::LOSS_AVERSION_FACTOR
      expect(result[:magnitude]).to be_within(0.001).of(expected_magnitude)
    end

    it 'does not apply loss aversion to gains' do
      store.shift_reference(domain: :financial, new_reference: 50.0)
      result = store.reference_frame(value: 100.0, domain: :financial)
      expect(result[:magnitude]).to be_within(0.001).of(50.0)
    end

    it 'uses anchor as implicit reference when no explicit reference set' do
      store.add(value: 50.0, domain: :financial)
      result = store.reference_frame(value: 100.0, domain: :financial)
      expect(result[:gain_or_loss]).to eq(:gain)
    end
  end

  describe '#decay_all' do
    it 'decays all anchors and returns pruned count' do
      store.add(value: 10.0, domain: :financial)
      pruned = store.decay_all
      expect(pruned).to be >= 0
    end

    it 'prunes anchors that fall below ANCHOR_FLOOR' do
      anchor = store.add(value: 10.0, domain: :financial)
      anchor.instance_variable_set(:@strength, Legion::Extensions::Anchoring::Helpers::Constants::ANCHOR_FLOOR - 0.001)
      store.decay_all
      expect(store.domains).not_to include(:financial)
    end

    it 'retains anchors above floor' do
      store.add(value: 10.0, domain: :financial)
      store.decay_all
      all = store.instance_variable_get(:@anchors)[:financial]
      expect(all).not_to be_nil
    end
  end

  describe '#shift_reference' do
    it 'sets new reference point for domain' do
      store.shift_reference(domain: :financial, new_reference: 100.0)
      refs = store.instance_variable_get(:@references)
      expect(refs[:financial]).to eq(100.0)
    end

    it 'returns old and new reference' do
      store.shift_reference(domain: :financial, new_reference: 50.0)
      result = store.shift_reference(domain: :financial, new_reference: 100.0)
      expect(result[:old_reference]).to eq(50.0)
      expect(result[:new_reference]).to eq(100.0)
    end

    it 'marks shift as significant when diff >= REFERENCE_SHIFT_THRESHOLD' do
      store.shift_reference(domain: :temporal, new_reference: 0.0)
      result = store.shift_reference(domain: :temporal, new_reference: 1.0)
      expect(result[:significant]).to be true
    end

    it 'marks shift as not significant when diff < REFERENCE_SHIFT_THRESHOLD' do
      store.shift_reference(domain: :temporal, new_reference: 0.0)
      result = store.shift_reference(domain: :temporal, new_reference: 0.1)
      expect(result[:significant]).to be false
    end
  end

  describe '#domains' do
    it 'returns empty array when no anchors' do
      expect(store.domains).to be_empty
    end

    it 'returns list of active domains' do
      store.add(value: 1.0, domain: :financial)
      store.add(value: 2.0, domain: :temporal)
      expect(store.domains).to match_array(%i[financial temporal])
    end
  end

  describe '#to_h' do
    it 'returns summary hash' do
      store.add(value: 10.0, domain: :financial)
      h = store.to_h
      expect(h).to include(:total_anchors, :domain_count, :domains, :references)
    end

    it 'reflects correct total_anchors count' do
      store.add(value: 10.0, domain: :financial)
      store.add(value: 20.0, domain: :financial)
      expect(store.to_h[:total_anchors]).to eq(2)
    end
  end
end
