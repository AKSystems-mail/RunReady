import React, { useState, useEffect } from 'react';
import { generateRunRoute } from './services/geminiService';
import { RoutePreferences, RouteData, UserStats, RunSession } from './types';
import { useGeolocation } from './hooks/useGeolocation';
import RouteCard from './components/RouteCard';
import StatsPanel from './components/StatsPanel';
import ActiveRunView from './components/ActiveRunView';
import RunSummaryModal from './components/RunSummaryModal';
import { Map, Zap, History, Loader2, Navigation, Menu, X, Activity, PlusCircle, Compass, Home } from 'lucide-react';

const STORAGE_KEY_STATS = 'rungenie_stats';
const STORAGE_KEY_ROUTES = 'rungenie_routes';
const STORAGE_KEY_PREFS = 'rungenie_last_prefs';

type ViewState = 'generate' | 'history' | 'stats';

export default function App() {
  const { coords, error: geoError, loading: geoLoading } = useGeolocation();
  
  // State
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [currentRoute, setCurrentRoute] = useState<RouteData | null>(null);
  const [savedRoutes, setSavedRoutes] = useState<RouteData[]>([]);
  const [view, setView] = useState<ViewState>('generate');
  const [menuOpen, setMenuOpen] = useState(false);
  
  // Active Run State
  const [activeRoute, setActiveRoute] = useState<RouteData | null>(null);
  const [lastSession, setLastSession] = useState<RunSession | null>(null);

  // Stats State
  const [stats, setStats] = useState<UserStats>({
    totalRuns: 0,
    totalDistanceKm: 0,
    totalTimeSeconds: 0
  });

  // Form State
  const [preferences, setPreferences] = useState<RoutePreferences>({
    distance: 3,
    unit: 'miles',
    routeType: 'loop',
    mode: 'local',
    customLocation: ''
  });

  // Init Data
  useEffect(() => {
    // Load Saved Data
    const savedStats = localStorage.getItem(STORAGE_KEY_STATS);
    if (savedStats) setStats(JSON.parse(savedStats));

    const savedRoutesData = localStorage.getItem(STORAGE_KEY_ROUTES);
    if (savedRoutesData) setSavedRoutes(JSON.parse(savedRoutesData));

    const lastPrefs = localStorage.getItem(STORAGE_KEY_PREFS);
    if (lastPrefs) setPreferences(JSON.parse(lastPrefs));
  }, []);

  // Save Effects
  useEffect(() => {
    localStorage.setItem(STORAGE_KEY_STATS, JSON.stringify(stats));
  }, [stats]);

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY_ROUTES, JSON.stringify(savedRoutes));
  }, [savedRoutes]);

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY_PREFS, JSON.stringify(preferences));
  }, [preferences]);


  const handleGenerate = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setCurrentRoute(null);

    // If no custom location and no geolocation
    if (!preferences.customLocation && !coords && !geoLoading) {
        setError("Please enable location services or enter a location manually.");
        setLoading(false);
        return;
    }

    try {
      const userCoords = coords ? { lat: coords.lat, lng: coords.lng } : undefined;
      const route = await generateRunRoute(preferences, userCoords);
      setCurrentRoute(route);
    } catch (err: any) {
      setError(err.message || "Something went wrong generating the route.");
    } finally {
      setLoading(false);
    }
  };

  const handleSaveRoute = (route: RouteData) => {
    if (savedRoutes.some(r => r.id === route.id)) return;
    setSavedRoutes([route, ...savedRoutes]);
  };

  const handleStartRun = (route: RouteData) => {
    setActiveRoute(route);
  };

  const handleFinishRun = (session: RunSession) => {
    // Convert distance to KM for standardized stats
    const distKm = session.unit === 'miles' 
      ? session.distance * 1.60934 
      : session.distance;

    setStats(prev => ({
      totalRuns: prev.totalRuns + 1,
      totalDistanceKm: prev.totalDistanceKm + distKm,
      totalTimeSeconds: (prev.totalTimeSeconds || 0) + session.durationSeconds,
      lastRunDate: Date.now()
    }));

    // Auto save the route if not already saved
    handleSaveRoute(currentRoute || savedRoutes.find(r => r.id === session.routeId)!);

    setActiveRoute(null);
    setLastSession(session);
  };

  const handleNavigation = (newView: ViewState) => {
    setView(newView);
    setMenuOpen(false);
  };

  // If running, show Active Run View
  if (activeRoute) {
    return (
        <ActiveRunView 
            route={activeRoute} 
            onFinish={handleFinishRun} 
            onCancel={() => setActiveRoute(null)} 
        />
    );
  }

  return (
    <div className="min-h-screen bg-slate-950 pb-20 font-sans">
      {/* Run Finished Modal */}
      {lastSession && (
        <RunSummaryModal 
            session={lastSession} 
            onClose={() => setLastSession(null)} 
        />
      )}

      {/* Header */}
      <header className="sticky top-0 z-50 bg-slate-900/90 backdrop-blur-md border-b border-slate-800">
        <div className="max-w-3xl mx-auto px-4 py-4 flex justify-between items-center">
          <div className="flex items-center gap-2 text-emerald-400 cursor-pointer" onClick={() => handleNavigation('generate')}>
            <div className="bg-emerald-500/20 p-2 rounded-lg">
                <Map size={24} />
            </div>
            <h1 className="text-xl font-bold tracking-tight text-white">Outdoor Run Finder</h1>
          </div>
          
          <button 
            onClick={() => setMenuOpen(!menuOpen)}
            className="text-slate-300 hover:text-white p-2 rounded-lg hover:bg-slate-800 transition-colors"
          >
            {menuOpen ? <X size={28} /> : <Menu size={28} />}
          </button>
        </div>
      </header>

      {/* Mobile Menu Overlay */}
      {menuOpen && (
        <div className="fixed inset-0 z-40 bg-slate-950/95 backdrop-blur-sm pt-24 px-6 animate-fade-in">
          <nav className="flex flex-col gap-4 text-center">
            <button 
              onClick={() => handleNavigation('generate')}
              className={`text-2xl font-bold py-4 border-b border-slate-800 transition-colors ${view === 'generate' ? 'text-emerald-400' : 'text-slate-300'}`}
            >
              <span className="flex items-center justify-center gap-3"><PlusCircle /> Plan Run</span>
            </button>
            <button 
              onClick={() => handleNavigation('history')}
              className={`text-2xl font-bold py-4 border-b border-slate-800 transition-colors ${view === 'history' ? 'text-emerald-400' : 'text-slate-300'}`}
            >
               <span className="flex items-center justify-center gap-3"><History /> History</span>
            </button>
            <button 
              onClick={() => handleNavigation('stats')}
              className={`text-2xl font-bold py-4 border-b border-slate-800 transition-colors ${view === 'stats' ? 'text-emerald-400' : 'text-slate-300'}`}
            >
               <span className="flex items-center justify-center gap-3"><Activity /> My Stats</span>
            </button>
          </nav>
        </div>
      )}

      <main className="max-w-3xl mx-auto px-4 py-6">
        
        {view === 'generate' && (
          <div className="space-y-8 animate-fade-in">
             {/* Input Form - Now at the top */}
             <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 shadow-xl">
               <h2 className="text-xl font-bold text-white mb-6 flex items-center gap-2">
                 <Navigation className="text-blue-400" /> Plan Your Run
               </h2>
               
               <form onSubmit={handleGenerate} className="space-y-6">
                 {/* Location */}
                 <div>
                   <label className="block text-slate-400 text-sm font-bold mb-2">Start Location</label>
                   <div className="relative">
                     <input 
                       type="text"
                       placeholder={geoLoading ? "Locating..." : "Current Location (or type address)"}
                       value={preferences.customLocation}
                       onChange={(e) => setPreferences({...preferences, customLocation: e.target.value})}
                       className="w-full bg-slate-800 text-white border border-slate-700 rounded-lg py-3 px-4 focus:outline-none focus:border-emerald-500 transition-colors"
                     />
                     {!preferences.customLocation && coords && (
                       <span className="absolute right-3 top-3.5 text-xs text-emerald-500 font-medium flex items-center gap-1">
                         <Zap size={12} fill="currentColor" /> GPS Active
                       </span>
                     )}
                   </div>
                   {geoError && !preferences.customLocation && (
                     <p className="text-red-400 text-xs mt-2">{geoError}. Please enter address manually.</p>
                   )}
                 </div>

                 <div className="grid grid-cols-2 gap-4">
                    {/* Distance */}
                    <div>
                      <label className="block text-slate-400 text-sm font-bold mb-2">Distance</label>
                      <div className="flex">
                        <input 
                          type="number"
                          step="0.1"
                          min="0.1"
                          max={preferences.unit === 'miles' ? 26.2 : 42.2}
                          value={preferences.distance}
                          onChange={(e) => setPreferences({...preferences, distance: parseFloat(e.target.value)})}
                          className="w-full bg-slate-800 text-white border border-slate-700 rounded-l-lg py-3 px-4 focus:outline-none focus:border-emerald-500"
                        />
                        <select 
                          value={preferences.unit}
                          onChange={(e) => setPreferences({...preferences, unit: e.target.value as any})}
                          className="bg-slate-700 text-white border-y border-r border-slate-700 rounded-r-lg px-3 focus:outline-none hover:bg-slate-600"
                        >
                          <option value="miles">mi</option>
                          <option value="km">km</option>
                        </select>
                      </div>
                    </div>

                    {/* Route Type */}
                    <div>
                      <label className="block text-slate-400 text-sm font-bold mb-2">Structure</label>
                      <select 
                         value={preferences.routeType}
                         onChange={(e) => setPreferences({...preferences, routeType: e.target.value as any})}
                         className="w-full bg-slate-800 text-white border border-slate-700 rounded-lg py-3 px-4 focus:outline-none focus:border-emerald-500 appearance-none"
                      >
                        <option value="loop">Loop</option>
                        <option value="finish-line">Point-to-Point</option>
                      </select>
                    </div>
                 </div>

                 {/* Mode Selection */}
                 <div>
                    <label className="block text-slate-400 text-sm font-bold mb-2">Route Mode</label>
                    <div className="grid grid-cols-2 gap-4">
                        <button
                            type="button"
                            onClick={() => setPreferences({...preferences, mode: 'local'})}
                            className={`flex flex-col items-center justify-center p-4 rounded-xl border transition-all ${
                                preferences.mode === 'local' 
                                ? 'bg-emerald-500/20 border-emerald-500 text-white' 
                                : 'bg-slate-800 border-slate-700 text-slate-400 hover:bg-slate-700'
                            }`}
                        >
                            <Home size={24} className={preferences.mode === 'local' ? 'text-emerald-400 mb-2' : 'mb-2'} />
                            <span className="font-bold text-sm">Local</span>
                            <span className="text-xs opacity-70">Nearby & Safe</span>
                        </button>

                        <button
                            type="button"
                            onClick={() => setPreferences({...preferences, mode: 'explorer'})}
                            className={`flex flex-col items-center justify-center p-4 rounded-xl border transition-all ${
                                preferences.mode === 'explorer' 
                                ? 'bg-blue-500/20 border-blue-500 text-white' 
                                : 'bg-slate-800 border-slate-700 text-slate-400 hover:bg-slate-700'
                            }`}
                        >
                            <Compass size={24} className={preferences.mode === 'explorer' ? 'text-blue-400 mb-2' : 'mb-2'} />
                            <span className="font-bold text-sm">Explorer</span>
                            <span className="text-xs opacity-70">Scenic & New</span>
                        </button>
                    </div>
                 </div>

                 <button 
                   type="submit"
                   disabled={loading}
                   className="w-full bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white font-bold py-4 rounded-xl shadow-lg shadow-emerald-900/40 transition-all transform active:scale-[0.98] disabled:opacity-70 disabled:cursor-not-allowed flex justify-center items-center gap-2"
                 >
                   {loading ? (
                     <><Loader2 className="animate-spin" /> Finding Route...</>
                   ) : (
                     "Generate Route"
                   )}
                 </button>
               </form>
             </div>

             {/* Results */}
             {error && (
               <div className="bg-red-500/10 border border-red-500/50 text-red-200 p-4 rounded-xl text-center animate-pulse">
                 {error}
               </div>
             )}

             {currentRoute && (
               <RouteCard 
                 route={currentRoute} 
                 onSave={handleSaveRoute}
                 isSaved={savedRoutes.some(r => r.id === currentRoute.id)}
                 onStartRun={handleStartRun}
               />
             )}
          </div>
        )}

        {view === 'history' && (
          <div className="space-y-6 animate-fade-in">
            <h2 className="text-2xl font-bold text-white flex items-center gap-2 mb-4">
              <History className="text-purple-400" /> Saved Routes
            </h2>
            {savedRoutes.length === 0 ? (
              <div className="text-center py-20 text-slate-500 bg-slate-900 rounded-2xl border border-slate-800">
                <p>No saved routes yet.</p>
                <button onClick={() => setView('generate')} className="text-emerald-400 hover:underline mt-2">Create one now</button>
              </div>
            ) : (
              savedRoutes.map(route => (
                <RouteCard 
                    key={route.id} 
                    route={route} 
                    isSaved={true} 
                    onStartRun={handleStartRun}
                />
              ))
            )}
          </div>
        )}

        {view === 'stats' && (
           <div className="animate-fade-in">
             <StatsPanel stats={stats} />
           </div>
        )}
      </main>
    </div>
  );
}