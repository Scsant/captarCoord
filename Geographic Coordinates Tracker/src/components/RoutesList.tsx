import { Download, Trash2, MapPin, Clock, Calendar } from 'lucide-react';
import { Button } from './ui/button';
import { Card } from './ui/card';
import { Badge } from './ui/badge';
import type { Route } from '../App';
import { toast } from 'sonner@2.0.3';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from './ui/alert-dialog';

interface RoutesListProps {
  routes: Route[];
  onRouteDelete: (routeId: string) => void;
}

export function RoutesList({ routes, onRouteDelete }: RoutesListProps) {
  const exportToJSON = (route: Route) => {
    const dataStr = JSON.stringify(route, null, 2);
    const dataBlob = new Blob([dataStr], { type: 'application/json' });
    const url = URL.createObjectURL(dataBlob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `${route.name.replace(/\s+/g, '_')}_${route.id}.json`;
    link.click();
    URL.revokeObjectURL(url);
    toast.success('Route exported as JSON!');
  };

  const exportToCSV = (route: Route) => {
    const headers = ['latitude', 'longitude', 'timestamp', 'accuracy', 'route_name'];
    const rows = route.points.map(point => [
      point.latitude,
      point.longitude,
      point.timestamp,
      point.accuracy || '',
      route.name
    ]);

    const csvContent = [
      headers.join(','),
      ...rows.map(row => row.join(','))
    ].join('\n');

    const dataBlob = new Blob([csvContent], { type: 'text/csv' });
    const url = URL.createObjectURL(dataBlob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `${route.name.replace(/\s+/g, '_')}_${route.id}.csv`;
    link.click();
    URL.revokeObjectURL(url);
    toast.success('Route exported as CSV!');
  };

  const formatDuration = (start: string, end?: string) => {
    if (!end) return 'In progress';
    const duration = new Date(end).getTime() - new Date(start).getTime();
    const minutes = Math.floor(duration / 60000);
    const seconds = Math.floor((duration % 60000) / 1000);
    return `${minutes}m ${seconds}s`;
  };

  if (routes.length === 0) {
    return (
      <Card className="p-12 bg-white/10 backdrop-blur-xl border-white/20 shadow-2xl text-center">
        <MapPin className="w-16 h-16 text-white/30 mx-auto mb-4" />
        <h3 className="text-white/80 mb-2">No Routes Yet</h3>
        <p className="text-white/50 text-sm">Start recording to save your first route</p>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      {routes.map((route) => (
        <Card key={route.id} className="p-5 bg-white/10 backdrop-blur-xl border-white/20 shadow-2xl hover:bg-white/15 transition-all">
          <div className="space-y-4">
            {/* Header */}
            <div className="flex items-start justify-between">
              <div className="flex-1">
                <h3 className="text-white text-lg mb-2">{route.name}</h3>
                <div className="flex flex-wrap gap-2">
                  <Badge className="bg-gradient-to-r from-cyan-500 to-blue-500 text-white border-0">
                    <MapPin className="w-3 h-3 mr-1" />
                    {route.totalPoints} points
                  </Badge>
                  <Badge className="bg-gradient-to-r from-purple-500 to-pink-500 text-white border-0">
                    <Clock className="w-3 h-3 mr-1" />
                    {formatDuration(route.startTime, route.endTime)}
                  </Badge>
                </div>
              </div>
            </div>

            {/* Info */}
            <div className="bg-white/5 rounded-xl p-3 border border-white/10 space-y-2">
              <div className="flex items-center gap-2 text-sm">
                <Calendar className="w-4 h-4 text-emerald-400" />
                <span className="text-white/60">Start:</span>
                <span className="text-white">{new Date(route.startTime).toLocaleString()}</span>
              </div>
              {route.endTime && (
                <div className="flex items-center gap-2 text-sm">
                  <Calendar className="w-4 h-4 text-pink-400" />
                  <span className="text-white/60">End:</span>
                  <span className="text-white">{new Date(route.endTime).toLocaleString()}</span>
                </div>
              )}
            </div>

            {/* Actions */}
            <div className="flex gap-2">
              <Button
                onClick={() => exportToJSON(route)}
                className="flex-1 bg-white/10 hover:bg-white/20 text-white border border-white/20"
              >
                <Download className="w-4 h-4 mr-2" />
                JSON
              </Button>
              <Button
                onClick={() => exportToCSV(route)}
                className="flex-1 bg-white/10 hover:bg-white/20 text-white border border-white/20"
              >
                <Download className="w-4 h-4 mr-2" />
                CSV
              </Button>
              <AlertDialog>
                <AlertDialogTrigger asChild>
                  <Button
                    variant="destructive"
                    className="bg-red-500/20 hover:bg-red-500/30 text-red-300 border border-red-400/30"
                  >
                    <Trash2 className="w-4 h-4" />
                  </Button>
                </AlertDialogTrigger>
                <AlertDialogContent className="bg-gray-900 border-white/20">
                  <AlertDialogHeader>
                    <AlertDialogTitle className="text-white">Delete Route?</AlertDialogTitle>
                    <AlertDialogDescription className="text-white/70">
                      This will permanently delete "{route.name}" and all its data points. This action cannot be undone.
                    </AlertDialogDescription>
                  </AlertDialogHeader>
                  <AlertDialogFooter>
                    <AlertDialogCancel className="bg-white/10 text-white border-white/20 hover:bg-white/20">
                      Cancel
                    </AlertDialogCancel>
                    <AlertDialogAction
                      onClick={() => {
                        onRouteDelete(route.id);
                        toast.success('Route deleted');
                      }}
                      className="bg-red-500 hover:bg-red-600 text-white"
                    >
                      Delete
                    </AlertDialogAction>
                  </AlertDialogFooter>
                </AlertDialogContent>
              </AlertDialog>
            </div>
          </div>
        </Card>
      ))}
    </div>
  );
}
