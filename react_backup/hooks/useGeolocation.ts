import { useState, useEffect } from 'react';

interface LocationState {
  coords: { lat: number; lng: number; speed?: number | null; accuracy?: number | null } | null;
  error: string | null;
  loading: boolean;
}

export const useGeolocation = () => {
  const [state, setState] = useState<LocationState>({
    coords: null,
    error: null,
    loading: true,
  });

  useEffect(() => {
    if (!navigator.geolocation) {
      setState({ coords: null, error: "Geolocation not supported", loading: false });
      return;
    }

    // Use watchPosition for continuous updates
    const watchId = navigator.geolocation.watchPosition(
      (position) => {
        setState({
          coords: {
            lat: position.coords.latitude,
            lng: position.coords.longitude,
            speed: position.coords.speed,
            accuracy: position.coords.accuracy
          },
          error: null,
          loading: false,
        });
      },
      (error) => {
        setState((prev) => ({ ...prev, error: error.message, loading: false }));
      },
      { 
        enableHighAccuracy: true, 
        timeout: 20000, 
        maximumAge: 1000 
      }
    );

    return () => {
      navigator.geolocation.clearWatch(watchId);
    };
  }, []);

  return state;
};