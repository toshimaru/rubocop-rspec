# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check that the first argument to the top-level describe is a constant.
      #
      # @example
      #   # bad
      #   describe 'Do something' do
      #   end
      #
      #   # good
      #   describe TestedClass do
      #     subject { described_class }
      #   end
      #
      #   describe 'TestedClass::VERSION' do
      #     subject { Object.const_get(self.class.description) }
      #   end
      #
      #   describe "A feature example", type: :feature do
      #   end
      class DescribeClass < Base
        include RuboCop::RSpec::TopLevelGroup

        MSG = 'The first argument to describe should be '\
              'the class or module being tested.'

        def_node_matcher :valid_describe?, <<-PATTERN
          {
            (send #{RSPEC} :describe const ...)
            (send #{RSPEC} :describe)
          }
        PATTERN

        def_node_matcher :describe_with_rails_metadata?, <<-PATTERN
          (send #{RSPEC} :describe !const ...
            (hash <#rails_metadata? ...>)
          )
        PATTERN

        def_node_matcher :rails_metadata?, <<-PATTERN
          (pair
            (sym :type)
            (sym {
                   :channel :controller :helper :job :mailer :model :request
                   :routing :view :feature :system :mailbox
                 }
            )
          )
        PATTERN

        def_node_matcher :described, <<~PATTERN
          (block $(send #{RSPEC} :describe $_ ...) ...)
        PATTERN

        def on_top_level_group(top_level_node)
          node, described = described(top_level_node)

          return unless described

          return if shared_group?(node) ||
            valid_describe?(node) ||
            describe_with_rails_metadata?(node) ||
            string_constant_describe?(described)

          add_offense(described)
        end

        private

        def string_constant_describe?(described_value)
          described_value.str_type? &&
            described_value.value.match?(/^(?:(?:::)?[A-Z]\w*)+$/)
        end
      end
    end
  end
end
