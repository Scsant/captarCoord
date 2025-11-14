import { useState, useEffect, useRef } from 'react';
import { Play, Square, Navigation, Clock, Target, AlertCircle, Info } from 'lucide-react';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Badge } from './ui/badge';
import { Card } from './ui/card';
import { Alert, AlertDescription } from './ui/alert';
import type { Route, CoordinatePoint } from '../App';
import { toast } from 'sonner@2.0.3';

interface RouteRecorderProps {
  onRouteSave: (route: Route) => void;
}

export function RouteRecorder({ onRouteSave }: RouteRecorderProps) {
  const [isRecording, setIsRecording] = useState(false);
  const [routeName, setRouteName] = useState('');
  const [currentPoints, setCurrentPoints] = useState<CoordinatePoint[]>([]);
  const [currentLocation, setCurrentLocation] = useState<CoordinatePoint | null>(null);
  const [error, setError] = useState<string>('');
  const [useMockData, setUseMockData] = useState(true); // Start with mock data by default
  const [hasTriedRealGPS, setHasTriedRealGPS] = useState(false);
  const [startTime, setStartTime] = useState<string>('');
  const intervalRef = useRef<NodeJS.Timeout | null>(null);
  const watchIdRef = useRef<number | null>(null);
  const mockBaseLatRef = useRef(-23.550520); // São Paulo
  const mockBaseLonRef = useRef(-46.633308);

  const generateMockPosition = (): CoordinatePoint => {
    // Simulate movement: small random changes
    mockBaseLatRef.current += (Math.random() - 0.5) * 0.0001;
    mockBaseLonRef.current += (Math.random() - 0.5) * 0.0001;

    return {
      latitude: mockBaseLatRef.current,
      longitude: mockBaseLonRef.current,
      timestamp: new Date().toISOString(),
      accuracy: Math.random() * 10 + 5 // 5-15m accuracy
    };
  };

  const getCurrentPosition = (): Promise<GeolocationPosition> => {
    return new Promise((resolve, reject) => {
      if (!navigator.geolocation) {
        reject(new Error('Geolocation is not supported by your browser'));
        return;
      }

      navigator.geolocation.getCurrentPosition(resolve, reject, {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0
      });
    });
  };

  const capturePoint = async () => {
    if (useMockData) {
      // Use mock data
      const point = generateMockPosition();
      setCurrentLocation(point);
      
      if (isRecording) {
        setCurrentPoints(prev => [...prev, point]);
      }
    } else {
      // Try to get real GPS data
      try {
        const position = await getCurrentPosition();
        const point: CoordinatePoint = {
          latitude: position.coords.latitude,
          longitude: position.coords.longitude,
          timestamp: new Date().toISOString(),
          accuracy: position.coords.accuracy
        };

        setCurrentLocation(point);
        setError('');
        
        if (isRecording) {
          setCurrentPoints(prev => [...prev, point]);
        }
      } catch (err: any) {
        // Silently switch to mock data if GPS fails
        if (!useMockData) {
          setUseMockData(true);
          toast.info('GPS unavailable. Using Demo Mode.');
          // Generate mock point
          const point = generateMockPosition();
          setCurrentLocation(point);
          
          if (isRecording) {
            setCurrentPoints(prev => [...prev, point]);
          }
        }
      }
    }
  };

  const tryRealGPS = async () => {
    setHasTriedRealGPS(true);
    try {
      const position = await getCurrentPosition();
      setUseMockData(false);
      setError('');
      toast.success('Real GPS activated!');
      
      const point: CoordinatePoint = {
        latitude: position.coords.latitude,
        longitude: position.coords.longitude,
        timestamp: new Date().toISOString(),
        accuracy: position.coords.accuracy
      };
      setCurrentLocation(point);
    } catch (err: any) {
      let errorMessage = 'GPS not available';
      if (err?.code === 1) {
        errorMessage = 'Location permission denied';
      } else if (err?.code === 2) {
        errorMessage = 'Location unavailable';
      } else if (err?.code === 3) {
        errorMessage = 'Location request timeout';
      }
      
      toast.error(errorMessage);
      setUseMockData(true);
    }
  };

  const startRecording = async () => {
    if (!routeName.trim()) {
      toast.error('Please enter a route name');
      return;
    }

    setError('');
    setCurrentPoints([]);
    setStartTime(new Date().toISOString());
    setIsRecording(true);

    // Capture first point immediately
    await capturePoint();

    // Then capture every 5 seconds
    intervalRef.current = setInterval(() => {
      capturePoint();
    }, 5000);

    toast.success('Recording started!');
  };

  const stopRecording = () => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }

    if (watchIdRef.current) {
      navigator.geolocation.clearWatch(watchIdRef.current);
      watchIdRef.current = null;
    }

    setIsRecording(false);

    if (currentPoints.length > 0) {
      const route: Route = {
        id: Date.now().toString(),
        name: routeName,
        points: currentPoints,
        startTime: startTime,
        endTime: new Date().toISOString(),
        totalPoints: currentPoints.length
      };

      onRouteSave(route);
      toast.success(`Route "${routeName}" saved with ${currentPoints.length} points!`);
      
      // Reset
      setRouteName('');
      setCurrentPoints([]);
    } else {
      toast.error('No points recorded');
    }
  };

  // Get initial location on mount
  useEffect(() => {
    capturePoint();
  }, []);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
      if (watchIdRef.current) {
        navigator.geolocation.clearWatch(watchIdRef.current);
      }
    };
  }, []);

  return (
    <div className="space-y-4">
      {/* Info Alert for Demo Mode */}
      {useMockData && (
        <Alert className="bg-blue-500/20 border-blue-400/30 backdrop-blur-xl">
          <Info className="h-4 w-4 text-blue-400" />
          <AlertDescription className="text-blue-200 flex items-center justify-between gap-3">
            <span>Demo Mode - Using simulated GPS data</span>
            {!isRecording && (
              <Button
                onClick={tryRealGPS}
                size="sm"
                className="bg-white/20 hover:bg-white/30 text-white border border-white/30 h-7 text-xs"
              >
                Try Real GPS
              </Button>
            )}
          </AlertDescription>
        </Alert>
      )}

      {/* Configuration Card */}
      <Card className="p-6 bg-white/10 backdrop-blur-xl border-white/20 shadow-2xl">
        <div className="space-y-4">
          <div>
            <Label htmlFor="routeName" className="text-white/90 mb-2 block">
              Route Name
            </Label>
            <Input
              id="routeName"
              placeholder="e.g., Morning Run, City Tour..."
              value={routeName}
              onChange={(e) => setRouteName(e.target.value)}
              disabled={isRecording}
              className="bg-white/10 border-white/30 text-white placeholder:text-white/50 backdrop-blur-sm"
            />
          </div>

          <div className="flex gap-3">
            {!isRecording ? (
              <Button
                onClick={startRecording}
                disabled={!routeName.trim()}
                className="flex-1 bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-600 hover:to-teal-600 text-white shadow-lg shadow-emerald-500/50"
              >
                <Play className="w-5 h-5 mr-2" />
                Start Recording
              </Button>
            ) : (
              <Button
                onClick={stopRecording}
                className="flex-1 bg-gradient-to-r from-red-500 to-pink-500 hover:from-red-600 hover:to-pink-600 text-white shadow-lg shadow-red-500/50"
              >
                <Square className="w-5 h-5 mr-2" />
                Stop Recording
              </Button>
            )}
          </div>
        </div>
      </Card>

      {/* Status Card */}
      {isRecording && (
        <Card className="p-5 bg-gradient-to-br from-emerald-500/20 to-teal-500/20 backdrop-blur-xl border-emerald-400/30 shadow-2xl animate-pulse">
          <div className="flex items-center gap-3">
            <div className="w-3 h-3 bg-emerald-400 rounded-full animate-pulse shadow-lg shadow-emerald-400/50"></div>
            <span className="text-white">Recording in progress...</span>
          </div>
        </Card>
      )}

      {/* Current Location Card */}
      {currentLocation && (
        <Card className="p-6 bg-white/10 backdrop-blur-xl border-white/20 shadow-2xl">
          <div className="space-y-4">
            <div className="flex items-center gap-2 mb-3">
              <Navigation className="w-5 h-5 text-cyan-400" />
              <h3 className="text-white">Current Location</h3>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="bg-white/5 rounded-xl p-4 border border-white/10">
                <div className="flex items-center gap-2 mb-2">
                  <Target className="w-4 h-4 text-blue-400" />
                  <span className="text-white/60 text-sm">Latitude</span>
                </div>
                <p className="text-white text-lg">{currentLocation.latitude.toFixed(6)}</p>
              </div>

              <div className="bg-white/5 rounded-xl p-4 border border-white/10">
                <div className="flex items-center gap-2 mb-2">
                  <Target className="w-4 h-4 text-purple-400" />
                  <span className="text-white/60 text-sm">Longitude</span>
                </div>
                <p className="text-white text-lg">{currentLocation.longitude.toFixed(6)}</p>
              </div>
            </div>

            <div className="bg-white/5 rounded-xl p-4 border border-white/10">
              <div className="flex items-center gap-2 mb-2">
                <Clock className="w-4 h-4 text-pink-400" />
                <span className="text-white/60 text-sm">Timestamp</span>
              </div>
              <p className="text-white">{new Date(currentLocation.timestamp).toLocaleString()}</p>
            </div>

            <div className="flex items-center gap-2 flex-wrap">
              {currentLocation.accuracy && (
                <Badge className="bg-blue-500/20 text-blue-300 border-blue-400/30">
                  Accuracy: ±{currentLocation.accuracy.toFixed(0)}m
                </Badge>
              )}
              {useMockData && (
                <Badge className="bg-yellow-500/20 text-yellow-300 border-yellow-400/30">
                  Demo Mode
                </Badge>
              )}
            </div>
          </div>
        </Card>
      )}

      {/* Points Counter */}
      {isRecording && currentPoints.length > 0 && (
        <Card className="p-5 bg-white/10 backdrop-blur-xl border-white/20 shadow-2xl">
          <div className="flex items-center justify-between">
            <span className="text-white/80">Points Recorded</span>
            <Badge className="bg-gradient-to-r from-cyan-500 to-blue-500 text-white border-0 text-lg px-4 py-1">
              {currentPoints.length}
            </Badge>
          </div>
        </Card>
      )}


    </div>
  );
}
