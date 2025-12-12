# frozen_string_literal: true

module Salvia
  module SSR
    module DomMock
      def self.generate_shim
        <<~JS
          (function() {
            // Mock DOM globals for SSR
            globalThis.window = globalThis;
            globalThis.self = globalThis;
            globalThis.addEventListener = function() {};
            globalThis.removeEventListener = function() {};
            globalThis.document = {
              createElement: function(tag) {
                return {
                  tagName: tag ? tag.toUpperCase() : 'DIV',
                  setAttribute: function() {},
                  appendChild: function() {},
                  style: {}
                };
              },
              createTextNode: function() { return {}; },
              addEventListener: function() { },
              removeEventListener: function() { },
              head: { appendChild: function() {} },
              body: { appendChild: function() {} },
              getElementById: function() { return null; },
              documentElement: {
                addEventListener: function() { },
                removeEventListener: function() { }
              }
            };
            globalThis.HTMLFormElement = class {};
            globalThis.HTMLElement = class {};
            globalThis.Element = class {};
            globalThis.Node = class {};
            globalThis.Event = class {};
            globalThis.CustomEvent = class {};
            globalThis.URL = class { 
              constructor(url) { this.href = url; } 
              static createObjectURL() { return ""; }
              static revokeObjectURL() { }
            };
            globalThis.requestAnimationFrame = function(cb) { return setTimeout(cb, 0); };
            globalThis.cancelAnimationFrame = function(id) { clearTimeout(id); };
            globalThis.navigator = { userAgent: 'SalviaSSR' };
            globalThis.location = { href: 'http://localhost' };
          })();
        JS
      end
    end
  end
end
