import React from 'react';
import { WeatherInfo } from '../types';
import { Sun, CloudRain, Thermometer, Sunrise, Sunset, AlertTriangle } from 'lucide-react';

interface WeatherWidgetProps {
  weather: WeatherInfo;
}

const WeatherWidget: React.FC<WeatherWidgetProps> = ({ weather }) => {
  return (
    <div className="bg-slate-800 rounded-xl p-5 border border-slate-700 mb-6">
      <div className="flex justify-between items-start mb-4">
        <h3 className="text-lg font-semibold text-slate-200 flex items-center gap-2">
          <Sun className="text-yellow-400" size={20} /> Current Conditions
        </h3>
        {weather.warnings.length > 0 && (
           <span className="bg-red-500/20 text-red-400 px-2 py-1 rounded text-xs font-bold uppercase flex items-center gap-1">
             <AlertTriangle size={12} /> Warning
           </span>
        )}
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {/* Temperature */}
        <div className={`p-3 rounded-lg flex flex-col items-center justify-center text-center
          ${weather.isComfortable ? 'bg-emerald-500/10 border border-emerald-500/20' : 'bg-orange-500/10 border border-orange-500/20'}
        `}>
          <Thermometer className={weather.isComfortable ? 'text-emerald-400' : 'text-orange-400'} size={24} />
          <span className="text-xl font-bold mt-1 text-white">{weather.temperature}</span>
          <span className="text-xs text-slate-400">Temp</span>
        </div>

        {/* Precipitation */}
        <div className="bg-slate-700/30 p-3 rounded-lg flex flex-col items-center justify-center text-center">
          <CloudRain className="text-blue-400" size={24} />
          <span className="text-sm font-semibold mt-1 text-white">{weather.precipitationChance}</span>
          <span className="text-xs text-slate-400">Precipitation</span>
        </div>

        {/* Sunrise */}
        <div className="bg-slate-700/30 p-3 rounded-lg flex flex-col items-center justify-center text-center">
          <Sunrise className="text-yellow-300" size={24} />
          <span className="text-sm font-semibold mt-1 text-white">{weather.sunrise}</span>
          <span className="text-xs text-slate-400">Sunrise</span>
        </div>

        {/* Sunset */}
        <div className="bg-slate-700/30 p-3 rounded-lg flex flex-col items-center justify-center text-center">
          <Sunset className="text-orange-300" size={24} />
          <span className="text-sm font-semibold mt-1 text-white">{weather.sunset}</span>
          <span className="text-xs text-slate-400">Sunset</span>
        </div>
      </div>

      {/* Warnings / Advice */}
      <div className="mt-4 pt-4 border-t border-slate-700">
        {!weather.isComfortable && (
          <p className="text-orange-300 text-sm mb-2">
            Running conditions might be uncomfortable. Check temperature.
          </p>
        )}
        {weather.warnings.map((warn, idx) => (
          <p key={idx} className="text-red-400 text-sm font-medium flex items-center gap-2">
            <AlertTriangle size={14} /> {warn}
          </p>
        ))}
        {weather.isComfortable && weather.warnings.length === 0 && (
          <p className="text-emerald-400 text-sm">Conditions look great for a run! 🏃</p>
        )}
      </div>
    </div>
  );
};

export default WeatherWidget;