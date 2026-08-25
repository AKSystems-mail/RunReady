export type DistanceUnit = 'miles' | 'km';
export type RouteType = 'loop' | 'finish-line';
export type RouteMode = 'local' | 'explorer';

export interface RoutePreferences {
  distance: number;
  unit: DistanceUnit;
  routeType: RouteType;
  mode: RouteMode; // New field
  customLocation?: string;
}

export interface WeatherInfo {
  temperature: string;
  condition: string;
  precipitationChance: string;
  sunrise: string;
  sunset: string;
  isComfortable: boolean;
  warnings: string[];
}

export interface RouteData {
  id: string;
  title: string;
  description: string;
  directions?: string[]; 
  mapData?: {
    start: string;
    end: string;
    waypoints: string[];
  };
  waypoints: Array<{
    title: string;
    uri: string;
  }>;
  weather?: WeatherInfo;
  createdAt: number;
  preferences: RoutePreferences;
}

export interface UserStats {
  totalRuns: number;
  totalDistanceKm: number;
  totalTimeSeconds?: number; // Added to track duration
  lastRunDate?: number;
}

export interface RunSession {
  routeId: string;
  startTime: number;
  endTime: number;
  durationSeconds: number;
  distance: number;
  unit: DistanceUnit;
}