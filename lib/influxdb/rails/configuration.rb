require "active_support/concern"

module InfluxDB
  module Rails
    module Configurable
      extend ActiveSupport::Concern

      class_methods do
        def defaults
          @defaults ||= {}
        end

        def set_defaults(**values) # rubocop:disable Naming/AccessorMethodName:
          defaults.merge! values
          attr_accessor(*defaults.keys)
        end
      end

      def load_defaults
        self.class.defaults.each do |key, value|
          val = value.dup rescue value
          public_send "#{key}=", val
        end
      end
    end
    private_constant :Configurable

    class ClientConfig
      include Configurable

      set_defaults(
        hosts:          ["localhost"].freeze,
        port:           8086,
        username:       "root".freeze,
        password:       "root".freeze,
        database:       nil,
        auth_method:    "params".freeze,
        auth_token:     nil,
        async:          true,
        use_ssl:        false,
        retry:          nil,
        open_timeout:   5,
        read_timeout:   300,
        max_delay:      30,
        time_precision: "s".freeze
      )

      def initialize
        load_defaults
      end
    end
    private_constant :ClientConfig

    class Configuration
      include Configurable

      set_defaults(
        measurement_name:        "rails".freeze,
        ignored_hooks:           [].freeze,
        tags_middleware:         ->(tags) { tags },
        rails_app_name:          nil,
        ignored_environments:    %w[test cucumber selenium].freeze,
        environment:             ::Rails.env,
        debug:                   false,
        instrumentation_enabled: true
      )

      # config option set after_initialize
      attr_accessor(:environment, :application_name)

      # configuration passed to InfluxDB::Client
      attr_reader :client

      # FIXME: Old configuration options, remove this in 1.0.1
      attr_writer \
        :series_name_for_controller_runtimes,
        :series_name_for_view_runtimes,
        :series_name_for_db_runtimes,
        :series_name_for_render_template,
        :series_name_for_render_partial,
        :series_name_for_render_collection,
        :series_name_for_sql,
        :series_name_for_exceptions,
        :series_name_for_instrumentation,
        :ignored_exceptions,
        :ignored_exception_messages,
        :ignored_user_agents,
        :application_root,
        :environment_variable_filters,
        :backtrace_filters,
        :influxdb_database,
        :influxdb_username,
        :influxdb_password,
        :influxdb_hosts,
        :influxdb_port,
        :async,
        :use_ssl,
        :retry,
        :open_timeout,
        :read_timeout,
        :max_delay,
        :time_precision

      def initialize
        @client = ClientConfig.new
        load_defaults
      end

      def debug?
        @debug
      end

      def instrumentation_enabled?
        @instrumentation_enabled
      end

      def ignore_current_environment?
        ignored_environments.include?(environment)
      end
    end
  end
end
