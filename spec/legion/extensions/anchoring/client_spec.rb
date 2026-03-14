# frozen_string_literal: true

require 'legion/extensions/anchoring/client'

RSpec.describe Legion::Extensions::Anchoring::Client do
  let(:client) { described_class.new }

  it 'responds to all runner methods' do
    expect(client).to respond_to(:record_anchor)
    expect(client).to respond_to(:evaluate_estimate)
    expect(client).to respond_to(:reference_frame)
    expect(client).to respond_to(:de_anchor)
    expect(client).to respond_to(:shift_reference)
    expect(client).to respond_to(:update_anchoring)
    expect(client).to respond_to(:domain_anchors)
    expect(client).to respond_to(:anchoring_stats)
  end

  it 'exposes anchor_store' do
    expect(client.anchor_store).to be_a(Legion::Extensions::Anchoring::Helpers::AnchorStore)
  end

  it 'accepts an external anchor_store' do
    custom_store = Legion::Extensions::Anchoring::Helpers::AnchorStore.new
    c = described_class.new(anchor_store: custom_store)
    expect(c.anchor_store).to be(custom_store)
  end

  it 'accepts keyword splat arguments' do
    expect { described_class.new(extra: :ignored) }.not_to raise_error
  end
end
