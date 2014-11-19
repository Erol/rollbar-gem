module Rollbar
  module Middleware
    module Rails
      module ShowExceptions
        include ExceptionReporter

        def render_exception_with_rollbar(env, exception)
          key = 'action_dispatch.show_detailed_exceptions'

          if exception.is_a?(ActionController::RoutingError) && env[key]
            scope = extract_scope_from(env)

            Rollbar.scoped(scope) do
              report_exception_to_rollbar(env, exception)
            end
          end

          render_exception_without_rollbar(env, exception)
        end

        def call_with_rollbar(env)
          call_without_rollbar(env)
        rescue ActionController::RoutingError => exception
          # won't reach here if show_detailed_exceptions is true
          scope = extract_scope_from(env)

          Rollbar.scoped(scope) do
            report_exception_to_rollbar(env, exception)
          end

          raise exception
        end

        def extract_scope_from(env)
          scope = env['rollbar.scope']
          Rollbar.log_warn('[Rollbar] rollbar.scope key has being removed from Rack env.') unless scope

          scope || {}
        end

        def self.included(base)
          base.send(:alias_method_chain, :call, :rollbar)
          base.send(:alias_method_chain, :render_exception, :rollbar)
        end
      end
    end
  end
end
