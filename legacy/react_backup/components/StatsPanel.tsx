import React from 'react';
import { UserStats } from '../types';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell } from 'recharts';
import { Trophy, Activity, Calendar } from 'lucide-react';

interface StatsPanelProps {
  stats: UserStats;
}

const StatsPanel: React.FC<StatsPanelProps> = ({ stats }) => {
  // Mock data for visualization based on the single total
  const data = [
    { name: 'Total', distance: stats.totalDistanceKm },
  ];

  return (
    <div className="bg-slate-800 rounded-xl p-6 shadow-lg border border-slate-700">
      <h2 className="text-xl font-bold text-white mb-6 flex items-center gap-2">
        <Activity className="text-emerald-400" /> Your Stats
      </h2>
      
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <div className="bg-slate-700/50 p-4 rounded-lg flex items-center gap-3">
          <div className="p-3 bg-blue-500/20 rounded-full text-blue-400">
            <Trophy size={24} />
          </div>
          <div>
            <p className="text-sm text-slate-400">Total Runs</p>
            <p className="text-2xl font-bold text-white">{stats.totalRuns}</p>
          </div>
        </div>

        <div className="bg-slate-700/50 p-4 rounded-lg flex items-center gap-3">
          <div className="p-3 bg-emerald-500/20 rounded-full text-emerald-400">
            <Activity size={24} />
          </div>
          <div>
            <p className="text-sm text-slate-400">Distance (km)</p>
            <p className="text-2xl font-bold text-white">{stats.totalDistanceKm.toFixed(1)}</p>
          </div>
        </div>

        <div className="bg-slate-700/50 p-4 rounded-lg flex items-center gap-3">
          <div className="p-3 bg-purple-500/20 rounded-full text-purple-400">
            <Calendar size={24} />
          </div>
          <div>
            <p className="text-sm text-slate-400">Last Run</p>
            <p className="text-lg font-bold text-white">
              {stats.lastRunDate ? new Date(stats.lastRunDate).toLocaleDateString() : 'N/A'}
            </p>
          </div>
        </div>
      </div>

      <div className="h-48 w-full mt-4">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={data} layout="vertical">
             <XAxis type="number" hide />
             <YAxis dataKey="name" type="category" hide />
             <Tooltip 
                contentStyle={{ backgroundColor: '#1e293b', border: 'none', borderRadius: '8px', color: '#fff' }}
                cursor={{fill: 'transparent'}}
             />
             <Bar dataKey="distance" fill="#10b981" radius={[0, 4, 4, 0]} barSize={40}>
               <Cell fill="#10b981" />
             </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
};

export default StatsPanel;