require "influxdb"
require "rails"

module InfluxDB
  module Rails
    class Railtie < ::Rails::Railtie # :nodoc:
      # rubocop:disable Metrics/BlockLength
      config.after_initialize do
        InfluxDB::Rails.configure do |config|
          config.environment ||= ::Rails.env
        end

        ActiveSupport.on_load(:action_controller) do
          require "influxdb/rails/instrumentation"
          include InfluxDB::Rails::Instrumentation

          before_action do
            current = InfluxDB::Rails.current
            current.request_id = request.request_id if request.respond_to?(:request_id)
          end
        end

        cache = lambda do |_, _, _, _, payload|
          current = InfluxDB::Rails.current
          current.controller = payload[:controller]
          current.action     = payload[:action]
        end
        ActiveSupport::Notifications.subscribe "start_processing.action_controller", &cache

        {
          "process_action.action_controller" => Middleware::RequestSubscriber,
          "render_template.action_view"      => Middleware::RenderSubscriber,
          "render_partial.action_view"       => Middleware::RenderSubscriber,
          "render_collection.action_view"    => Middleware::RenderSubscriber,
          "sql.active_record"                => Middleware::SqlSubscriber,
        }.each do |hook_name, subscriber_class|
          subscribe_to(hook_name, subscriber_class)
        end
      end
      # rubocop:enable Metrics/BlockLength

      def subscribe_to(hook_name, subscriber_class)
        subscriber = subscriber_class.new(InfluxDB::Rails.configuration, hook_name)
        ActiveSupport::Notifications.subscribe hook_name, subscriber
      end
    end
  end
end
