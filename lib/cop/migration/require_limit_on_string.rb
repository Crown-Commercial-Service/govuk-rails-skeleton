module RuboCop
  module Cop
    module Migration
      class RequireLimitOnString < RuboCop::Cop::Base
        MSG = 'Specify a limit when using the `string` column type. Use `text` if no limit is needed'.freeze

        def on_send(node)
          case node.method_name
          when :add_column
            check_options node, node.arguments[2], node.last_argument
          when :column
            check_options node, node.arguments[1], node.last_argument
          when :string
            check_options node, node.method_name, node.last_argument
          end
        end

        private

        def check_options(node, type, opts)
          return unless type == :string

          add_offense(node.loc.expression) unless length_option_set?(opts)
        end

        def length_option_set?(opts)
          return false unless opts.hash_type?

          opts.pairs.any? do |pair|
            pair.key.value == :limit
          end
        end
      end
    end
  end
end
