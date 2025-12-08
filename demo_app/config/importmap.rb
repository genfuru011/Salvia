Salvia.importmap.draw do
  # Preact + HTM
  pin "preact", to: "https://esm.sh/preact@10.19.3"
  pin "preact/hooks", to: "https://esm.sh/preact@10.19.3/hooks?external=preact"
  pin "htm/preact", to: "https://esm.sh/htm@3.1.1/preact?external=preact"
  pin "chart.js/auto", to: "https://esm.sh/chart.js@4.4.1/auto"
  pin "lucide-preact", to: "https://esm.sh/lucide-preact@0.309.0?external=preact"

  # アプリケーションの Islands
  pin "SalesChart", to: "/islands/SalesChart.js"
  pin "StatsCard", to: "/islands/StatsCard.js"
  pin "MainChart", to: "/islands/MainChart.js"
  pin "RevenueChart", to: "/islands/RevenueChart.js"
end
