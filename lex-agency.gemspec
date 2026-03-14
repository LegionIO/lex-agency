# frozen_string_literal: true

require_relative 'lib/legion/extensions/agency/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-agency'
  spec.version       = Legion::Extensions::Agency::VERSION
  spec.authors       = ['Matthew Iverson']
  spec.email         = ['matt@iverson.io']

  spec.summary       = 'Self-efficacy and agency modeling for LegionIO'
  spec.description   = "Implements Bandura's self-efficacy theory for LegionIO agents — " \
                       'tracks belief in ability to achieve outcomes across domains, ' \
                       'mastery experiences, vicarious learning, and agency attribution.'
  spec.homepage      = 'https://github.com/LegionIO/lex-agency'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.files         = Dir['lib/**/*', 'LICENSE', 'README.md']
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'
end
