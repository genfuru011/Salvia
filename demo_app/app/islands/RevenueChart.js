import { html } from 'htm/preact';
import { useRef, useEffect } from 'preact/hooks';
import Chart from 'chart.js/auto';
import { PieChart } from 'lucide-preact';

export function RevenueChart() {
  const canvasRef = useRef(null);
  const chartRef = useRef(null);

  useEffect(() => {
    if (!canvasRef.current) return;
    if (chartRef.current) chartRef.current.destroy();

    const ctx = canvasRef.current.getContext('2d');
    
    chartRef.current = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: ['Online', 'Offline', 'Combined'],
        datasets: [{
          data: [45, 35, 20],
          backgroundColor: ['#3b82f6', '#93c5fd', '#e2e8f0'],
          borderWidth: 0,
          hoverOffset: 4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        cutout: '80%',
        plugins: {
          legend: { display: false },
          tooltip: { enabled: false }
        }
      }
    });

    return () => {
      if (chartRef.current) chartRef.current.destroy();
    };
  }, []);

  return html`
    <div class="bg-white p-6 rounded-md border border-slate-100 shadow-sm h-full">
      <div class="flex justify-between items-center mb-6">
        <h3 class="text-slate-500 text-sm font-medium flex items-center gap-2">
          <span class="p-1 bg-slate-50 rounded-full">
            <${PieChart} size=${14} />
          </span>
          Revenue Overview
        </h3>
        <select class="text-xs border-none bg-slate-50 rounded px-2 py-1 text-slate-600 outline-none cursor-pointer">
          <option>This Month</option>
        </select>
      </div>
      <div class="relative h-48 flex justify-center items-center mb-4">
        <canvas ref=${canvasRef}></canvas>
        <div class="absolute text-center">
          <div class="text-[10px] text-slate-400 font-bold tracking-wider mb-0.5">REVENUE</div>
          <div class="text-2xl font-bold text-slate-900 font-sans">$2.34M</div>
        </div>
      </div>
      
      <div class="grid grid-cols-3 gap-2">
        <div class="text-center p-3 rounded-md border border-slate-50 hover:bg-slate-50 transition-colors">
          <div class="flex justify-center mb-2 text-blue-500"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"></rect><line x1="8" y1="21" x2="16" y2="21"></line><line x1="12" y1="17" x2="12" y2="21"></line></svg></div>
          <div class="text-[10px] text-slate-500 font-medium mb-0.5">Online</div>
          <div class="font-bold text-slate-900 text-sm">$940K</div>
        </div>
        <div class="text-center p-3 rounded-md border border-slate-50 hover:bg-slate-50 transition-colors">
          <div class="flex justify-center mb-2 text-blue-300"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 21h18"/><path d="M5 21V7a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v14"/><path d="M9 10a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2"/></svg></div>
          <div class="text-[10px] text-slate-500 font-medium mb-0.5">Offline</div>
          <div class="font-bold text-slate-900 text-sm">$800K</div>
        </div>
        <div class="text-center p-3 rounded-md border border-slate-50 hover:bg-slate-50 transition-colors">
          <div class="flex justify-center mb-2 text-slate-400"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="1" x2="12" y2="23"></line><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path></svg></div>
          <div class="text-[10px] text-slate-500 font-medium mb-0.5">Combined</div>
          <div class="font-bold text-slate-900 text-sm">$940K</div>
        </div>
      </div>
      
      <div class="mt-4 p-3 bg-slate-50 rounded-md flex items-center gap-2 text-xs text-slate-500">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-slate-400"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>
        Your monthly revenue hit is $2.00M
      </div>
    </div>
  `;
}
