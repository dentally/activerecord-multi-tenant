# Add generic warning when queries fail and there is no tenant set
module MultiTenant
  # Option to enable query monitor
  @@enable_query_monitor = false
  def self.enable_query_monitor; @@enable_query_monitor = true; end
  def self.query_monitor_enabled?; @@enable_query_monitor; end

  class QueryMonitor
    def finish(_name, _id, _payload); end

    def start(_name, _id, payload)
      return unless MultiTenant.query_monitor_enabled?
      return unless MultiTenant.current_tenant_id.nil?
      return if MultiTenant.explicit_without
      return if call_part_of_setup?(payload[:sql])

      message = 'WARNING: Tenant not present - make sure to add MultiTenant.with(tenant) {...}'
      ActiveRecord::Base.logger.warn "#{message} #{payload[:sql]}"
    end

    private

    def call_part_of_setup?(trace)
      call_to_set_or_show(trace) || call_to_pg_tables(trace)
    end

    def call_to_set_or_show(trace)
      trace =~ /^SET/ || trace =~ /^SHOW/
    end

    def call_to_pg_tables(trace)
      trace =~ /FROM pg_type/ ||
        trace =~ /FROM pg_attribute/ ||
        trace =~ /FROM pg_namespace/ ||
        trace =~ /FROM pg_class/ ||
        trace =~ /FROM pg_index/
    end
  end
end

ActiveSupport::Notifications.subscribe('sql.active_record', MultiTenant::QueryMonitor.new)
