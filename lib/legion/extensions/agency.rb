# frozen_string_literal: true

require_relative 'agency/version'
require_relative 'agency/helpers/constants'
require_relative 'agency/helpers/outcome_event'
require_relative 'agency/helpers/efficacy_model'
require_relative 'agency/runners/agency'
require_relative 'agency/client'

module Legion
  module Extensions
    module Agency
      extend Legion::Extensions::Core if defined?(Legion::Extensions::Core)
    end
  end
end
