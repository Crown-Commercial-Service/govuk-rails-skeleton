module RuboCop
  module Cop
    module Migration
      class RequireUUIDPrimaryKeys < RuboCop::Cop::Base
        MSG = 'Use UUIDs for database primary keys (with the `id: :uuid` option)'.freeze

        def on_send(node)
          return unless node.method_name == :create_table

          add_offense(node.loc.expression) unless uuid_option_set?(node)
        end

        private

        def uuid_option_set?(node)
          return false unless node.last_argument.hash_type?

          node.last_argument.pairs.any? do |pair|
            pair.key.value == :id && pair.value.value == :uuid
          end
        end
      end
    end
  end
end
