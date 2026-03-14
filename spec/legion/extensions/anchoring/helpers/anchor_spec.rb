# frozen_string_literal: true

RSpec.describe Legion::Extensions::Anchoring::Helpers::Anchor do
  subject(:anchor) { described_class.new(value: 100.0, domain: :financial) }

  describe '#initialize' do
    it 'sets value as float' do
      expect(anchor.value).to eq(100.0)
    end

    it 'sets domain as symbol' do
      expect(anchor.domain).to eq(:financial)
    end

    it 'sets initial strength to 1.0' do
      expect(anchor.strength).to eq(1.0)
    end

    it 'generates a uuid id' do
      expect(anchor.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets created_at' do
      expect(anchor.created_at).to be_a(Time)
    end

    it 'sets last_accessed' do
      expect(anchor.last_accessed).to be_a(Time)
    end

    it 'accepts integer value and converts to float' do
      a = described_class.new(value: 50, domain: :general)
      expect(a.value).to eq(50.0)
    end

    it 'defaults domain to :general when not specified' do
      a = described_class.new(value: 10.0)
      expect(a.domain).to eq(:general)
    end
  end

  describe '#decay' do
    it 'reduces strength by ANCHOR_DECAY' do
      before = anchor.strength
      anchor.decay
      expect(anchor.strength).to be_within(0.001).of(before - Legion::Extensions::Anchoring::Helpers::Constants::ANCHOR_DECAY)
    end

    it 'does not go below 0.0' do
      50.times { anchor.decay }
      expect(anchor.strength).to eq(0.0)
    end
  end

  describe '#reinforce' do
    it 'updates the value toward observed_value via EMA' do
      anchor.reinforce(observed_value: 200.0)
      expect(anchor.value).to be > 100.0
      expect(anchor.value).to be < 200.0
    end

    it 'bumps strength up (capped at 1.0)' do
      anchor.decay
      before = anchor.strength
      anchor.reinforce(observed_value: 100.0)
      expect(anchor.strength).to be > before
    end

    it 'updates last_accessed' do
      before = anchor.last_accessed
      sleep 0.001
      anchor.reinforce(observed_value: 100.0)
      expect(anchor.last_accessed).to be >= before
    end
  end

  describe '#pull' do
    it 'returns a value between anchor value and estimate' do
      result = anchor.pull(estimate: 200.0)
      expect(result).to be > 100.0
      expect(result).to be < 200.0
    end

    it 'pulls estimate closer to anchor value' do
      biased = anchor.pull(estimate: 200.0)
      expect((biased - 100.0).abs).to be < (200.0 - 100.0).abs
    end

    it 'returns anchor value when estimate equals anchor value' do
      result = anchor.pull(estimate: 100.0)
      expect(result).to be_within(0.001).of(100.0)
    end
  end

  describe '#label' do
    it 'returns :strong at full strength' do
      expect(anchor.label).to eq(:strong)
    end

    it 'returns :moderate at moderate strength' do
      anchor.instance_variable_set(:@strength, 0.6)
      expect(anchor.label).to eq(:moderate)
    end

    it 'returns :weak at weak strength' do
      anchor.instance_variable_set(:@strength, 0.35)
      expect(anchor.label).to eq(:weak)
    end

    it 'returns :fading at very low strength' do
      anchor.instance_variable_set(:@strength, 0.1)
      expect(anchor.label).to eq(:fading)
    end
  end

  describe '#to_h' do
    it 'returns a hash with all expected keys' do
      h = anchor.to_h
      expect(h).to include(:id, :value, :domain, :strength, :label, :created_at, :last_accessed)
    end

    it 'includes correct value' do
      expect(anchor.to_h[:value]).to eq(100.0)
    end

    it 'includes label' do
      expect(anchor.to_h[:label]).to eq(:strong)
    end
  end
end
