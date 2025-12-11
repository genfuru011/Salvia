# frozen_string_literal: true

module Salvia
  class PathResolver
    def self.resolve(name)
      # Check flat structure
      path = File.join(Salvia.root, "#{name}.tsx")
      return path if File.exist?(path)

      roots = [
        "salvia/app/pages",
        "salvia/app/islands",
        "salvia/app/components"
      ]
      
      roots.each do |root|
        path = File.join(Salvia.root, root, "#{name}.tsx")
        return path if File.exist?(path)
        
        path = File.join(Salvia.root, root, "#{name}.jsx")
        return path if File.exist?(path)
        
        path = File.join(Salvia.root, root, "#{name}.js")
        return path if File.exist?(path)
      end
      
      if name.include?("/")
         path = File.join(Salvia.root, "salvia/app", "#{name}.tsx")
         return path if File.exist?(path)
         
         path = File.join(Salvia.root, "salvia/app", "#{name}.jsx")
         return path if File.exist?(path)
         
         path = File.join(Salvia.root, "salvia/app", "#{name}.js")
         return path if File.exist?(path)
      end
      
      nil
    end
  end
end
