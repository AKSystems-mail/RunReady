import React, { useState } from 'react';
import { RouteData } from '../types';
import { Share2, MapPin, Navigation, ExternalLink, Save, ChevronDown, ChevronUp, PlayCircle } from 'lucide-react';
import WeatherWidget from './WeatherWidget';

interface RouteCardProps {
  route: RouteData;
  onSave?: (route: RouteData) => void;
  isSaved?: boolean;
  onStartRun?: (route: RouteData) => void;
}

const RouteCard: React.FC<RouteCardProps> = ({ route, onSave, isSaved, onStartRun }) => {
  const [showDirections, setShowDirections] = useState(false);

  const handleShare = async () => {
    const shareData = {
      title: 'My Outdoor Run Route',
      text: `Check out this ${route.preferences.distance}${route.preferences.unit} run I found on Outdoor Run Finder: ${route.title}`,
      url: window.location.href 
    };

    if (navigator.share) {
      try {
        await navigator.share(shareData);
      } catch (err) {
        console.log('Share canceled');
      }
    } else {
      navigator.clipboard.writeText(`${shareData.text}\n\nDescription: ${route.description}`);
      alert("Route details copied to clipboard!");
    }
  };

  // Construct map URL for driving directions preview style
  let mapUrl = "";
  let externalMapUrl = "";

  if (route.mapData) {
    const saddr = encodeURIComponent(route.mapData.start);
    let daddrParam = encodeURIComponent(route.mapData.end);
    
    // Add waypoints to daddr
    if (route.mapData.waypoints && route.mapData.waypoints.length > 0) {
        const intermediate = route.mapData.waypoints.map(w => encodeURIComponent(w)).join('+to:');
        daddrParam = `${intermediate}+to:${encodeURIComponent(route.mapData.end)}`;
    }

    mapUrl = `https://maps.google.com/maps?saddr=${saddr}&daddr=${daddrParam}&output=embed&t=m`;
    externalMapUrl = `https://www.google.com/maps/dir/?api=1&origin=${saddr}&destination=${encodeURIComponent(route.mapData.end)}&travelmode=walking`;
    if(route.mapData.waypoints.length > 0) {
        externalMapUrl += `&waypoints=${route.mapData.waypoints.map(w => encodeURIComponent(w)).join('|')}`;
    }

  } else {
    // Fallback if structured map data missing
    const mapQuery = encodeURIComponent(`${route.title} ${route.preferences.customLocation || ''}`);
    mapUrl = `https://maps.google.com/maps?q=${mapQuery}&t=&z=14&ie=UTF8&iwloc=&output=embed`;
    externalMapUrl = `https://www.google.com/maps/search/?api=1&query=${mapQuery}`;
  }

  return (
    <div className="bg-slate-900 border border-slate-700 rounded-2xl overflow-hidden shadow-2xl animate-fade-in relative">
      {/* Header */}
      <div className="bg-gradient-to-r from-emerald-900/50 to-slate-900 p-6 border-b border-slate-700">
        <div className="flex justify-between items-start">
          <div>
            <div className="flex items-center gap-2 mb-2">
              <span className="bg-emerald-500 text-emerald-950 text-xs font-bold px-2 py-1 rounded-full uppercase tracking-wider">
                {route.preferences.distance} {route.preferences.unit}
              </span>
              <span className="bg-slate-700 text-slate-300 text-xs font-bold px-2 py-1 rounded-full uppercase tracking-wider">
                {route.preferences.routeType === 'loop' ? 'Loop' : 'P2P'}
              </span>
               <span className="bg-slate-700 text-slate-300 text-xs font-bold px-2 py-1 rounded-full uppercase tracking-wider">
                {route.preferences.mode === 'local' ? 'Local' : 'Explorer'}
              </span>
            </div>
            <h2 className="text-2xl font-bold text-white">{route.title}</h2>
          </div>
          <div className="flex gap-2">
            <button 
              onClick={handleShare}
              className="p-2 bg-slate-800 hover:bg-slate-700 text-blue-400 rounded-full transition-colors"
              title="Share Route"
            >
              <Share2 size={20} />
            </button>
            {onSave && (
              <button 
                onClick={() => onSave(route)}
                disabled={isSaved}
                className={`p-2 rounded-full transition-colors ${
                  isSaved 
                    ? 'bg-emerald-500/20 text-emerald-400 cursor-default' 
                    : 'bg-slate-800 hover:bg-emerald-900/50 text-emerald-400'
                }`}
                title="Save Route"
              >
                <Save size={20} />
              </button>
            )}
          </div>
        </div>
      </div>

      <div className="p-6">
        {route.weather && <WeatherWidget weather={route.weather} />}

        <div className="mb-6">
          <p className="text-slate-300 leading-relaxed text-sm md:text-base">{route.description}</p>
        </div>

        {/* Action Button: Start Run */}
        {onStartRun && (
            <button 
                onClick={() => onStartRun(route)}
                className="w-full mb-6 bg-emerald-600 hover:bg-emerald-500 text-white font-bold py-4 rounded-xl shadow-lg shadow-emerald-900/40 transition-all transform active:scale-[0.98] flex justify-center items-center gap-2"
            >
                <PlayCircle size={24} fill="currentColor" className="text-emerald-200" /> 
                START RUN
            </button>
        )}

        {/* Turn by Turn Dropdown */}
        {route.directions && route.directions.length > 0 && (
          <div className="mb-6 border border-slate-700 rounded-xl overflow-hidden">
            <button 
              onClick={() => setShowDirections(!showDirections)}
              className="w-full bg-slate-800 p-4 flex justify-between items-center text-left hover:bg-slate-750 transition-colors"
            >
              <span className="text-slate-200 font-bold flex items-center gap-2">
                <Navigation size={16} className="text-emerald-400" /> 
                Turn-by-Turn Directions
              </span>
              {showDirections ? <ChevronUp size={20} className="text-slate-400" /> : <ChevronDown size={20} className="text-slate-400" />}
            </button>
            
            {showDirections && (
              <div className="bg-slate-800/50 p-4 border-t border-slate-700">
                <ul className="space-y-3">
                  {route.directions.map((step, idx) => (
                    <li key={idx} className="flex gap-3 text-sm text-slate-300">
                      <span className="flex-shrink-0 w-6 h-6 rounded-full bg-slate-700 text-slate-400 flex items-center justify-center text-xs font-bold border border-slate-600">
                        {idx + 1}
                      </span>
                      <span className="pt-0.5">{step}</span>
                    </li>
                  ))}
                </ul>
              </div>
            )}
          </div>
        )}

        {/* Map View */}
        <div className="w-full h-64 bg-slate-800 rounded-xl overflow-hidden border border-slate-700 mb-6 relative">
             <iframe 
               width="100%" 
               height="100%" 
               frameBorder="0" 
               scrolling="no" 
               marginHeight={0} 
               marginWidth={0} 
               src={mapUrl}
               title="Route Map"
               className="filter grayscale-[20%] contrast-[1.1] opacity-90 hover:opacity-100 transition-opacity"
             ></iframe>
             <div className="absolute bottom-2 right-2">
                <a 
                    href={externalMapUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="bg-white/90 text-slate-900 text-xs font-bold px-3 py-1.5 rounded-md shadow hover:bg-white flex items-center gap-1"
                >
                    <ExternalLink size={12} /> Open in Maps
                </a>
             </div>
        </div>

        <div className="pt-4 border-t border-slate-800 flex gap-4 justify-start items-center flex-wrap">
            <span className="text-slate-500 text-xs font-bold uppercase mr-2">Sync with:</span>
            <a 
               href="https://www.strava.com/" 
               target="_blank" 
               rel="noreferrer"
               className="text-orange-500 hover:text-orange-400 text-sm font-medium transition-colors"
            >
              Strava
            </a>
            <a 
               href="https://runkeeper.com/" 
               target="_blank" 
               rel="noreferrer"
               className="text-cyan-500 hover:text-cyan-400 text-sm font-medium transition-colors"
            >
              Runkeeper
            </a>
            <a 
               href="https://www.google.com/fit/" 
               target="_blank" 
               rel="noreferrer"
               className="text-blue-500 hover:text-blue-400 text-sm font-medium transition-colors"
            >
              Google Fit
            </a>
        </div>
      </div>
    </div>
  );
};

export default RouteCard;