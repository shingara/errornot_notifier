module ErrornotNotifier
  module Rails
    module JavascriptNotifier
      def self.included(base) #:nodoc:
        base.send(:after_filter, :insert_errornot_javascript_notifier)
      end

      private

      def insert_errornot_javascript_notifier
        return unless ErrornotNotifier.configuration.public?
        return unless ErrornotNotifier.configuration.js_notifier

        path = File.join(File.dirname(__FILE__), '..', '..', 'templates', 'javascript_notifier.erb')
        host = ErrornotNotifier.configuration.host.dup
        port = ErrornotNotifier.configuration.port
        host << ":#{port}" unless [80, 443].include?(port)

        options = {
          :file          => path,
          :layout        => false,
          :use_full_path => false,
          :locals        => {
            :host        => host,
            :secure      => ErrornotNotifier.configuration.secure,
            :api_key     => ErrornotNotifier.configuration.api_key,
            :environment => ErrornotNotifier.configuration.environment_name
          }
        }

        if @template
          javascript = @template.render(options)
        else
          javascript = render_to_string(options)
        end

        if response.body.respond_to?(:gsub)
          response.body = response.body.gsub(/<(head)>/i, "<\\1>\n" + javascript)
        end
      end
    end
  end
end
