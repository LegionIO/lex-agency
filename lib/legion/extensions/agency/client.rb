# frozen_string_literal: true

module Legion
  module Extensions
    module Agency
      class Client
        include Runners::Agency

        attr_reader :efficacy_model

        def initialize(efficacy_model: nil, **)
          @efficacy_model = efficacy_model || Helpers::EfficacyModel.new
        end
      end
    end
  end
end
