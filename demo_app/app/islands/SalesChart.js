import { useEffect, useRef } from 'preact/hooks';
import { html } from 'htm/preact';
import Chart from 'chart.js/auto';

export function SalesChart({ data, labels, label }) {
  const canvasRef = useRef(null);
  const chartRef = useRef(null);

  useEffect(() => {
    if (!canvasRef.current) return;

    // 既存のチャートがあれば破棄
    if (chartRef.current) {
      chartRef.current.destroy();
    }

    const ctx = canvasRef.current.getContext('2d');
    chartRef.current = new Chart(ctx, {
      type: 'line',
      data: {
        labels: labels || ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
        datasets: [{
          label: label || 'Sales',
          data: data || [12, 19, 3, 5, 2, 3],
          borderColor: 'rgb(75, 192, 192)',
          tension: 0.1
        }]
      },
      options: {
        responsive: true,
        animation: {
          duration: 1000,
          easing: 'easeOutQuart'
        }
      }
    });

    return () => {
      if (chartRef.current) {
        chartRef.current.destroy();
      }
    };
  }, [data, labels, label]);

  return html`
    <div class="p-4 bg-white rounded shadow">
      <h3 class="text-lg font-bold mb-4">${label}</h3>
      <canvas ref=${canvasRef}></canvas>
    </div>
  `;
}
