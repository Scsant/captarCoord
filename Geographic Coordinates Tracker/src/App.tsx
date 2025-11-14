import { useState } from 'react';
import { RouteRecorder } from './components/RouteRecorder';
import { RoutesList } from './components/RoutesList';
import { MapPin, Database } from 'lucide-react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './components/ui/tabs';

export interface CoordinatePoint {
  latitude: number;
  longitude: number;
  timestamp: string;
  accuracy?: number;
}

export interface Route {
  id: string;
  name: string;
  points: CoordinatePoint[];
  startTime: string;
  endTime?: string;
  totalPoints: number;
}

export default function App() {
  const [routes, setRoutes] = useState<Route[]>([]);

  const handleRouteSave = (route: Route) => {
    setRoutes(prev => [route, ...prev]);
  };

  const handleRouteDelete = (routeId: string) => {
    setRoutes(prev => prev.filter(r => r.id !== routeId));
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-indigo-950 via-purple-900 to-pink-900 pb-20">
      {/* Header */}
      <div className="relative overflow-hidden">
        <div className="absolute inset-0 bg-black/20 backdrop-blur-sm"></div>
        <div className="relative px-6 pt-8 pb-6">
          <div className="flex items-center gap-3 mb-2">
            <div className="p-3 rounded-2xl bg-gradient-to-br from-cyan-400 to-blue-500 shadow-lg shadow-blue-500/50">
              <MapPin className="w-7 h-7 text-white" />
            </div>
            <h1 className="text-white text-3xl">Controller</h1>
          </div>
          <p className="text-white/70 ml-1">Track & Save Geographic Data</p>
        </div>
      </div>

      {/* Main Content */}
      <div className="px-4 mt-6">
        <Tabs defaultValue="record" className="w-full">
          <TabsList className="grid w-full grid-cols-2 bg-white/10 backdrop-blur-md border border-white/20 p-1">
            <TabsTrigger 
              value="record"
              className="data-[state=active]:bg-white/20 data-[state=active]:text-white text-white/60 data-[state=active]:shadow-lg"
            >
              <MapPin className="w-4 h-4 mr-2" />
              Record
            </TabsTrigger>
            <TabsTrigger 
              value="routes"
              className="data-[state=active]:bg-white/20 data-[state=active]:text-white text-white/60 data-[state=active]:shadow-lg"
            >
              <Database className="w-4 h-4 mr-2" />
              Routes ({routes.length})
            </TabsTrigger>
          </TabsList>

          <TabsContent value="record" className="mt-6">
            <RouteRecorder onRouteSave={handleRouteSave} />
          </TabsContent>

          <TabsContent value="routes" className="mt-6">
            <RoutesList routes={routes} onRouteDelete={handleRouteDelete} />
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
}
