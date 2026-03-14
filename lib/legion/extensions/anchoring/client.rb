# frozen_string_literal: true

require 'legion/extensions/anchoring/helpers/constants'
require 'legion/extensions/anchoring/helpers/anchor'
require 'legion/extensions/anchoring/helpers/anchor_store'
require 'legion/extensions/anchoring/runners/anchoring'

module Legion
  module Extensions
    module Anchoring
      class Client
        include Runners::Anchoring

        attr_reader :anchor_store

        def initialize(anchor_store: nil, **)
          @anchor_store = anchor_store || Helpers::AnchorStore.new
        end
      end
    end
  end
end
