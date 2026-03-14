# frozen_string_literal: true

require 'legion/extensions/anchoring/version'
require 'legion/extensions/anchoring/helpers/constants'
require 'legion/extensions/anchoring/helpers/anchor'
require 'legion/extensions/anchoring/helpers/anchor_store'
require 'legion/extensions/anchoring/runners/anchoring'

module Legion
  module Extensions
    module Anchoring
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
