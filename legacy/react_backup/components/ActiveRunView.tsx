import React, { useState, useEffect, useRef } from 'react';
import { RouteData, RunSession } from '../types';
import { StopCircle, Play, Pause, ChevronRight, ChevronLeft, Volume2, VolumeX, Map as MapIcon, Navigation } from 'lucide-react';
import { useGeolocation } from '../hooks/useGeolocation';

interface ActiveRunViewProps {
  route: RouteData;
  onFinish: (session: RunSession) => void;
  onCancel: () => void;
}

const ActiveRunView: React.FC<ActiveRunViewProps> = ({ route, onFinish, onCancel }) => {
  const [elapsedSeconds, setElapsedSeconds] = useState(0);
  const [isPaused, setIsPaused] = useState(false);
  const [currentStep, setCurrentStep] = useState(0);
  const [isMuted, setIsMuted] = useState(false);
  const [showMap, setShowMap] = useState(false);
  
  // Live Geolocation for tracking
  const { coords } = useGeolocation();

  const directions = route.directions || ["Start your run! Follow the route description."];
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // Trigger haptic feedback
  const triggerHaptic = (pattern: number | number[]) => {
    if (navigator.vibrate) {
      navigator.vibrate(pattern);
    }
  };

  // Start Timer on Mount
  useEffect(() => {
    // Initial start vibration
    triggerHaptic(200);

    if (!isPaused) {
      timerRef.current = setInterval(() => {
        setElapsedSeconds(prev => prev + 1);
      }, 1000);
    } 

    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, []); // Run once on mount

  // Handle Pause/Resume Timer logic
  useEffect(() => {
    if (isPaused) {
      if (timerRef.current) clearInterval(timerRef.current);
    } else {
       // Avoid setting multiple intervals if effect re-runs
       if (timerRef.current) clearInterval(timerRef.current);
       timerRef.current = setInterval(() => {
        setElapsedSeconds(prev => prev + 1);
      }, 1000);
    }
  }, [isPaused]);

  // TTS & Haptic Effect for Steps
  useEffect(() => {
    const isFinalStep = currentStep === directions.length - 1;

    // Haptic feedback for step change
    if (isFinalStep) {
        triggerHaptic([200, 100, 500]); // Distinct pattern for finish line/last step
    } else {
        triggerHaptic(100); // Short blip for normal step
    }

    if (!isMuted && 'speechSynthesis' in window) {
      window.speechSynthesis.cancel();
      
      const text = directions[currentStep];
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.rate = 1.0;
      utterance.pitch = 1.0;
      window.speechSynthesis.speak(utterance);
    }
  }, [currentStep, isMuted, directions]);

  const handlePauseToggle = () => {
    const newState = !isPaused;
    setIsPaused(newState);
    // Haptic: 50ms triple pulse for pause, single 200ms for resume
    triggerHaptic(newState ? [50, 50, 50] : 200);
  };

  const handleStop = () => {
    if (timerRef.current) clearInterval(timerRef.current);
    triggerHaptic(500); // Long vibration on stop
    
    const session: RunSession = {
        routeId: route.id,
        startTime: Date.now() - (elapsedSeconds * 1000),
        endTime: Date.now(),
        durationSeconds: elapsedSeconds,
        distance: route.preferences.distance,
        unit: route.preferences.unit
    };
    onFinish(session);
  };

  const formatTime = (totalSeconds: number) => {
    const hrs = Math.floor(totalSeconds / 3600);
    const mins = Math.floor((totalSeconds % 3600) / 60);
    const secs = totalSeconds % 60;
    
    if (hrs > 0) {
        return `${hrs}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  // Construct map URL for live view (reusing logic from RouteCard)
  let mapUrl = "";
  if (route.mapData) {
    const saddr = encodeURIComponent(route.mapData.start);
    let daddrParam = encodeURIComponent(route.mapData.end);
    if (route.mapData.waypoints && route.mapData.waypoints.length > 0) {
        const intermediate = route.mapData.waypoints.map(w => encodeURIComponent(w)).join('+to:');
        daddrParam = `${intermediate}+to:${encodeURIComponent(route.mapData.end)}`;
    }
    mapUrl = `https://maps.google.com/maps?saddr=${saddr}&daddr=${daddrParam}&output=embed&t=m`;
  } else {
    const mapQuery = encodeURIComponent(`${route.title} ${route.preferences.customLocation || ''}`);
    mapUrl = `https://maps.google.com/maps?q=${mapQuery}&t=&z=14&ie=UTF8&iwloc=&output=embed`;
  }

  return (
    <div className="fixed inset-0 z-50 bg-slate-900 flex flex-col animate-fade-in">
      {/* Top Bar */}
      <div className="p-4 bg-slate-800 border-b border-slate-700 flex justify-between items-center shadow-md z-10">
        <h2 className="text-white font-bold truncate pr-4 text-sm md:text-base">{route.title}</h2>
        <div className="flex gap-2">
            <button 
                onClick={() => setShowMap(!showMap)} 
                className={`p-2 rounded-full transition ${showMap ? 'bg-emerald-500/20 text-emerald-400' : 'text-slate-400 hover:bg-slate-700'}`}
                title="Toggle Map"
            >
                <MapIcon size={20} />
            </button>
            <button 
                onClick={() => setIsMuted(!isMuted)} 
                className="text-slate-400 p-2 rounded-full hover:bg-slate-700 transition"
                title={isMuted ? "Unmute" : "Mute"}
            >
                {isMuted ? <VolumeX size={20} /> : <Volume2 size={20} className="text-emerald-400" />}
            </button>
        </div>
      </div>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col relative overflow-hidden">
         
         {/* Map Overlay or Timer */}
         {showMap ? (
            <div className="flex-1 relative bg-slate-800">
                <iframe 
                   width="100%" 
                   height="100%" 
                   frameBorder="0" 
                   src={mapUrl}
                   title="Route Map"
                   className="opacity-90 grayscale-[20%]"
                ></iframe>
                {/* GPS Status Overlay */}
                <div className="absolute top-4 left-4 bg-slate-900/90 backdrop-blur px-3 py-2 rounded-lg border border-slate-700 shadow-lg">
                    <div className="flex items-center gap-2">
                        <span className="relative flex h-3 w-3">
                          <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                          <span className="relative inline-flex rounded-full h-3 w-3 bg-emerald-500"></span>
                        </span>
                        <span className="text-xs font-bold text-white">Live Tracking</span>
                    </div>
                    {coords && coords.accuracy && (
                        <p className="text-[10px] text-slate-400 mt-1 ml-5">
                            Accuracy: +/- {Math.round(coords.accuracy)}m
                        </p>
                    )}
                </div>
            </div>
         ) : (
            <div className="flex-1 flex flex-col justify-center items-center p-6">
                <div className="text-8xl font-mono font-bold text-white tracking-tighter mb-4 drop-shadow-2xl">
                    {formatTime(elapsedSeconds)}
                </div>
                <div className="text-emerald-500 text-sm font-bold uppercase tracking-[0.2em] mb-8">Elapsed Time</div>
                
                {coords && (
                    <div className="flex gap-6 text-center">
                       {coords.speed !== null && coords.speed !== undefined && (
                         <div>
                             <p className="text-2xl font-bold text-white">{(coords.speed * 2.23694).toFixed(1)}</p>
                             <p className="text-xs text-slate-400 uppercase">MPH</p>
                         </div>
                       )}
                    </div>
                )}
            </div>
         )}

         {/* Directions Card - Floating at bottom */}
         <div className="bg-slate-800 border-t border-slate-700 p-6 shadow-[0_-4px_20px_rgba(0,0,0,0.3)] z-20">
             <div className="flex justify-between items-start mb-4">
                 <div>
                    <div className="flex items-center gap-2 mb-2">
                        <Navigation size={12} className="text-emerald-400" />
                        <span className="text-emerald-500 text-xs font-bold uppercase">Current Instruction</span>
                    </div>
                    <p className="text-xl md:text-2xl font-bold text-white leading-tight pr-2">
                        {directions[currentStep]}
                    </p>
                 </div>
             </div>
             
             <div className="flex justify-between items-center mt-4">
                <button 
                    disabled={currentStep === 0}
                    onClick={() => setCurrentStep(prev => Math.max(0, prev - 1))}
                    className="p-4 rounded-full bg-slate-700 text-white disabled:opacity-30 disabled:cursor-not-allowed hover:bg-slate-600 transition active:scale-95"
                >
                    <ChevronLeft size={24} />
                </button>
                <span className="text-slate-400 font-mono text-sm">
                    {currentStep + 1} / {directions.length}
                </span>
                <button 
                    disabled={currentStep === directions.length - 1}
                    onClick={() => setCurrentStep(prev => Math.min(directions.length - 1, prev + 1))}
                    className={`p-4 rounded-full text-white disabled:opacity-30 disabled:cursor-not-allowed transition active:scale-95 shadow-lg ${
                        currentStep === directions.length - 1 
                        ? 'bg-emerald-600 hover:bg-emerald-500 shadow-emerald-900/50' 
                        : 'bg-slate-700 hover:bg-slate-600'
                    }`}
                >
                    {currentStep === directions.length - 1 ? <StopCircle size={24} /> : <ChevronRight size={24} />}
                </button>
             </div>
         </div>
      </div>

      {/* Controls */}
      <div className="bg-slate-900 p-6 pb-8 grid grid-cols-2 gap-4 border-t border-slate-800">
         <button 
            onClick={handlePauseToggle}
            className="flex items-center justify-center gap-2 bg-slate-800 text-white font-bold py-4 rounded-2xl hover:bg-slate-700 transition active:scale-95 border border-slate-700"
         >
            {isPaused ? <><Play size={20} className="text-emerald-400" /> Resume</> : <><Pause size={20} className="text-yellow-400" /> Pause</>}
         </button>
         
         <button 
            onClick={handleStop}
            className="flex items-center justify-center gap-2 bg-red-500/10 text-red-500 font-bold py-4 rounded-2xl hover:bg-red-500 hover:text-white transition active:scale-95 border border-red-500/20"
         >
            <StopCircle size={20} /> Stop Run
         </button>
      </div>
    </div>
  );
};

export default ActiveRunView;