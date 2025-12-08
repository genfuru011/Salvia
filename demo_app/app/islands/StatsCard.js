import { html } from 'htm/preact';
import { ArrowUpRight, ArrowDownRight } from 'lucide-preact';

export function StatsCard({ title, value, change, trend, subtext }) {
  const isPositive = trend === 'up';
  const TrendIcon = isPositive ? ArrowUpRight : ArrowDownRight;
  const trendColor = isPositive ? 'text-green-600 bg-green-100' : 'text-red-600 bg-red-100';

  return html`
    <div class="bg-white p-5 rounded-md border border-slate-100 shadow-sm hover:shadow-md transition-shadow duration-200">
      <div class="flex justify-between items-start mb-3">
        <h3 class="text-slate-500 text-sm font-medium">${title}</h3>
        <div class="p-1.5 rounded-md ${isPositive ? 'bg-slate-50' : 'bg-slate-50'}">
           <${TrendIcon} size=${16} class="text-slate-400" />
        </div>
      </div>
      <div class="flex items-baseline gap-2 mb-1">
        <span class="text-2xl font-bold text-slate-900 font-sans">${value}</span>
        <span class="text-xs font-bold px-2 py-0.5 rounded-full ${trendColor}">
          ${change}
        </span>
      </div>
      <p class="text-slate-400 text-xs font-medium">${subtext}</p>
    </div>
  `;
}
