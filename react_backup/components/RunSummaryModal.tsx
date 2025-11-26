import React from 'react';
import { RunSession } from '../types';
import { Share2, CheckCircle, ExternalLink, X } from 'lucide-react';

interface RunSummaryModalProps {
  session: RunSession;
  onClose: () => void;
}

const RunSummaryModal: React.FC<RunSummaryModalProps> = ({ session, onClose }) => {
  
  const formatTime = (totalSeconds: number) => {
    const mins = Math.floor(totalSeconds / 60);
    const secs = totalSeconds % 60;
    return `${mins}m ${secs}s`;
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center px-4 bg-slate-950/80 backdrop-blur-sm animate-fade-in">
      <div className="bg-slate-900 w-full max-w-md rounded-2xl border border-slate-700 shadow-2xl overflow-hidden relative">
        <button onClick={onClose} className="absolute top-4 right-4 text-slate-400 hover:text-white">
            <X size={24} />
        </button>

        <div className="bg-emerald-600/20 p-8 flex flex-col items-center justify-center border-b border-slate-800">
            <div className="bg-emerald-500 rounded-full p-4 mb-4 text-emerald-950 shadow-[0_0_20px_rgba(16,185,129,0.5)]">
                <CheckCircle size={48} />
            </div>
            <h2 className="text-2xl font-bold text-white">Run Complete!</h2>
            <p className="text-emerald-400 font-medium">Great job out there.</p>
        </div>

        <div className="p-6">
            <div className="grid grid-cols-2 gap-4 mb-6">
                <div className="bg-slate-800 p-4 rounded-xl text-center">
                    <p className="text-slate-400 text-xs font-bold uppercase mb-1">Distance</p>
                    <p className="text-2xl font-bold text-white">
                        {session.distance} <span className="text-sm font-normal text-slate-400">{session.unit}</span>
                    </p>
                </div>
                <div className="bg-slate-800 p-4 rounded-xl text-center">
                    <p className="text-slate-400 text-xs font-bold uppercase mb-1">Time</p>
                    <p className="text-2xl font-bold text-white">{formatTime(session.durationSeconds)}</p>
                </div>
            </div>
            
            <p className="text-center text-slate-400 text-sm mb-4">
                Your stats have been saved locally. <br/>Transmit data to your favorite app:
            </p>

            <div className="space-y-3">
                <a 
                    href="https://www.google.com/fit/"
                    target="_blank"
                    rel="noreferrer"
                    className="flex items-center justify-between p-3 bg-slate-800 hover:bg-slate-700 rounded-lg group transition"
                >
                    <span className="font-semibold text-white group-hover:text-blue-400 transition">Google Fit</span>
                    <ExternalLink size={16} className="text-slate-500" />
                </a>
                <a 
                    href="https://www.strava.com/upload/select"
                    target="_blank"
                    rel="noreferrer"
                    className="flex items-center justify-between p-3 bg-slate-800 hover:bg-slate-700 rounded-lg group transition"
                >
                    <span className="font-semibold text-white group-hover:text-orange-400 transition">Strava</span>
                    <ExternalLink size={16} className="text-slate-500" />
                </a>
                <a 
                    href="https://runkeeper.com/"
                    target="_blank"
                    rel="noreferrer"
                    className="flex items-center justify-between p-3 bg-slate-800 hover:bg-slate-700 rounded-lg group transition"
                >
                    <span className="font-semibold text-white group-hover:text-cyan-400 transition">Runkeeper</span>
                    <ExternalLink size={16} className="text-slate-500" />
                </a>
            </div>

            <button 
                onClick={onClose}
                className="w-full mt-6 bg-slate-700 hover:bg-slate-600 text-white font-bold py-3 rounded-xl transition"
            >
                Close Summary
            </button>
        </div>
      </div>
    </div>
  );
};

export default RunSummaryModal;