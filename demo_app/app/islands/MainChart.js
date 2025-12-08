import { html } from 'htm/preact';
import { useRef, useEffect } from 'preact/hooks';
import Chart from 'chart.js/auto';
import { Clock } from 'lucide-preact';

export function MainChart({ data, labels }) {
  const canvasRef = useRef(null);
  const chartRef = useRef(null);

  useEffect(() => {
    if (!canvasRef.current) return;
    if (chartRef.current) chartRef.current.destroy();

    const ctx = canvasRef.current.getContext('2d');
    
    const gradient = ctx.createLinearGradient(0, 0, 0, 300);
    gradient.addColorStop(0, 'rgba(59, 130, 246, 0.2)');
    gradient.addColorStop(1, 'rgba(59, 130, 246, 0.0)');

    chartRef.current = new Chart(ctx, {
      type: 'line',
      data: {
        labels: labels || ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
        datasets: [{
          label: 'Conversion',
          data: data || [12, 19, 3, 5, 2, 3],
          borderColor: '#3b82f6',
          backgroundColor: gradient,
          fill: true,
          tension: 0.4,
          pointRadius: 0,
          pointHoverRadius: 6,
          borderWidth: 2
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            mode: 'index',
            intersect: false,
            backgroundColor: '#1e293b',
            titleColor: '#f8fafc',
            bodyColor: '#f8fafc',
            padding: 10,
            cornerRadius: 7,
            displayColors: false
          }
        },
        scales: {
          x: {
            grid: { display: false },
            ticks: { color: '#94a3b8', font: { family: '"Plus Jakarta Sans"' } }
          },
          y: {
            grid: { color: '#f1f5f9', borderDash: [5, 5] },
            ticks: { color: '#94a3b8', font: { family: '"Plus Jakarta Sans"' } },
            border: { display: false }
          }
        },
        interaction: {
          mode: 'nearest',
          axis: 'x',
          intersect: false
        }
      }
    });

    return () => {
      if (chartRef.current) chartRef.current.destroy();
    };
  }, [data, labels]);

  return html`
    <div class="bg-white p-6 rounded-md border border-slate-100 shadow-sm h-full">
      <div class="flex justify-between items-center mb-6">
        <div>
          <h3 class="text-slate-500 text-sm font-medium flex items-center gap-2">
            <span class="p-1 bg-slate-50 rounded-full">
              <${Clock} size=${14} />
            </span>
            Conversion Analysis
          </h3>
          <div class="flex items-baseline gap-2 mt-1">
            <span class="text-2xl font-bold text-slate-900 font-sans">22.5%</span>
            <span class="text-xs font-bold px-2 py-0.5 rounded-full text-green-600 bg-green-100">+3.2%</span>
          </div>
        </div>
        <button class="text-xs font-medium text-slate-500 hover:text-slate-700">See More</button>
      </div>
      <div class="h-64">
        <canvas ref=${canvasRef}></canvas>
      </div>
    </div>
  `;
}
