# frozen_string_literal: true

RSpec.describe Legion::Extensions::Anchoring::Helpers::Constants do
  it 'defines DEFAULT_ANCHOR_WEIGHT as 0.6' do
    expect(described_module::DEFAULT_ANCHOR_WEIGHT).to eq(0.6)
  end

  it 'defines ADJUSTMENT_RATE as 0.1' do
    expect(described_module::ADJUSTMENT_RATE).to eq(0.1)
  end

  it 'defines ANCHOR_DECAY as 0.02' do
    expect(described_module::ANCHOR_DECAY).to eq(0.02)
  end

  it 'defines ANCHOR_FLOOR as 0.05' do
    expect(described_module::ANCHOR_FLOOR).to eq(0.05)
  end

  it 'defines MAX_ANCHORS_PER_DOMAIN as 20' do
    expect(described_module::MAX_ANCHORS_PER_DOMAIN).to eq(20)
  end

  it 'defines MAX_DOMAINS as 50' do
    expect(described_module::MAX_DOMAINS).to eq(50)
  end

  it 'defines REFERENCE_SHIFT_THRESHOLD as 0.3' do
    expect(described_module::REFERENCE_SHIFT_THRESHOLD).to eq(0.3)
  end

  it 'defines LOSS_AVERSION_FACTOR as 2.25' do
    expect(described_module::LOSS_AVERSION_FACTOR).to eq(2.25)
  end

  it 'defines ANCHOR_LABELS with 4 entries' do
    expect(described_module::ANCHOR_LABELS.size).to eq(4)
  end

  it 'ANCHOR_LABELS maps high strength to :strong' do
    label = described_module::ANCHOR_LABELS.find { |range, _| range.cover?(0.9) }&.last
    expect(label).to eq(:strong)
  end

  it 'ANCHOR_LABELS maps mid strength to :moderate' do
    label = described_module::ANCHOR_LABELS.find { |range, _| range.cover?(0.6) }&.last
    expect(label).to eq(:moderate)
  end

  it 'ANCHOR_LABELS maps low strength to :weak' do
    label = described_module::ANCHOR_LABELS.find { |range, _| range.cover?(0.3) }&.last
    expect(label).to eq(:weak)
  end

  it 'ANCHOR_LABELS maps very low strength to :fading' do
    label = described_module::ANCHOR_LABELS.find { |range, _| range.cover?(0.1) }&.last
    expect(label).to eq(:fading)
  end

  def described_module
    Legion::Extensions::Anchoring::Helpers::Constants
  end
end
