module Salvia
  class Compiler
    module Adapters
      class DenoSidecar
        def bundle(entry_point, **options)
          Salvia::Sidecar.instance.bundle(entry_point, **options)
        end

        def check(entry_point)
          Salvia::Sidecar.instance.check(entry_point)
        end

        def fmt(entry_point)
          Salvia::Sidecar.instance.fmt(entry_point)
        end

        def shutdown
          Salvia::Sidecar.instance.stop
        end
      end
    end
  end
end
