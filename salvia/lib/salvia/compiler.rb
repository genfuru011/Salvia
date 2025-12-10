module Salvia
  class Compiler
    class Error < StandardError; end

    class << self
      attr_writer :adapter

      def adapter
        @adapter ||= Salvia::Compiler::Adapters::DenoSidecar.new
      end

      def bundle(entry_point, **options)
        adapter.bundle(entry_point, **options)
      end

      def check(entry_point)
        adapter.check(entry_point)
      end

      def fmt(entry_point)
        adapter.fmt(entry_point)
      end

      def shutdown
        adapter.shutdown if adapter.respond_to?(:shutdown)
      end
    end
  end
end
