import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../constants/api_endpoints.dart';
import '../network/auth_interceptor.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Centralized Socket.IO Service for managing real-time driver tracking & ride status updates
class SocketService {
  final FlutterSecureStorage _secureStorage;
  socket_io.Socket? _socket;

  final _locationUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _rideStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get locationUpdates => _locationUpdateController.stream;
  Stream<Map<String, dynamic>> get rideStatusUpdates => _rideStatusController.stream;
  Stream<bool> get connectionState => _connectionStateController.stream;

  bool get isConnected => _socket?.connected ?? false;
  String? _currentJoinedRideId;

  SocketService({FlutterSecureStorage? secureStorage}) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  ///Initialize and connect socket client using saved JWT auth token
  Future<void> initSocket() async {
    if (_socket != null && _socket!.connected) {
      print('⚡ [Socket] Socket already connected with ID: ${_socket!.id}');
      return;
    }

    final token = await _secureStorage.read(key: AuthInterceptor.tokenKey);
    final baseUrl = ApiEndpoints.baseUrl;

    print('⚡ [Socket] Initializing Socket.IO connection to: $baseUrl (Token: ${token != null ? "Present" : "Missing"})');

    try {
      _socket = socket_io.io(
        baseUrl,
        socket_io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token ?? ''})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(2000)
            .build(),
      );

      _socket!.onConnect((_) {
        print('✅ [Socket] Rider Socket Connected! ID: ${_socket!.id}');
        _connectionStateController.add(true);

        // Re-join active ride room if connection was interrupted
        if (_currentJoinedRideId != null) {
          joinRide(_currentJoinedRideId!);
        }
      });

      _socket!.onConnectError((err) {
        print('❌ [Socket] Connection Error: $err');
        _connectionStateController.add(false);
      });

      _socket!.onDisconnect((reason) {
        print('⚠️ [Socket] Disconnected: $reason');
        _connectionStateController.add(false);
      });

      _socket!.on('ride_joined', (data) {
        print('🎉 [Socket] Successfully joined tracking room: $data');
      });

      // 1. Driver Location Updates Stream (`driver:location_updated`)
      _socket!.on('driver:location_updated', (data) {
        print('📍 [Socket] Driver Location Update: $data');
        if (data is Map<String, dynamic>) {
          _locationUpdateController.add(data);
        } else if (data is Map) {
          _locationUpdateController.add(Map<String, dynamic>.from(data));
        }
      });

      // 2. Ride Status Transition Stream
      void handleStatusEvent(dynamic data) {
        print('🔄 [Socket] Ride Status Changed: $data');
        if (data is Map<String, dynamic>) {
          _rideStatusController.add(data);
        } else if (data is Map) {
          _rideStatusController.add(Map<String, dynamic>.from(data));
        }
      }
      _socket!.on('ride:status_changed', handleStatusEvent);
      _socket!.on('ride.status_changed', handleStatusEvent);
      _socket!.on('ride_status_updated', handleStatusEvent);
      _socket!.on('ride_status_change', handleStatusEvent);
      _socket!.on('ride_status', handleStatusEvent);
      _socket!.on('ride:completed', handleStatusEvent);
      _socket!.on('ride_completed', handleStatusEvent);
      _socket!.on('ride:updated', handleStatusEvent);
      _socket!.on('ride_updated', handleStatusEvent);

      _socket!.connect();
    } catch (e) {
      print('❌ [Socket] Failed to initialize socket: $e');
    }
  }

  /// Subscribe to driver location stream for a specific ride
  void joinRide(String rideId) {
    if (rideId.isEmpty) return;
    _currentJoinedRideId = rideId;

    if (_socket == null || !_socket!.connected) {
      print('⚡ [Socket] Socket not connected yet. Connecting before joining room for ride: $rideId');
      initSocket().then((_) {
        _emitJoinRide(rideId);
      });
    } else {
      _emitJoinRide(rideId);
    }
  }

  void _emitJoinRide(String rideId) {
    print('🚀 [Socket Emit] Emitting join_ride for rideId: $rideId');
    _socket?.emit('join_ride', {'rideId': rideId});
  }

  /// Leave ride tracking room and unsubscribe
  void leaveRide(String rideId) {
    if (rideId.isEmpty) return;
    print('🚪 [Socket Emit] Emitting leave_ride for rideId: $rideId');
    _socket?.emit('leave_ride', {'rideId': rideId});
    if (_currentJoinedRideId == rideId) {
      _currentJoinedRideId = null;
    }
  }

  /// Emit cancel ride event to socket server
  void cancelRide(String rideId, {String? reason}) {
    if (rideId.isEmpty) return;
    print('🚀 [Socket Emit] Emitting cancel_ride for rideId: $rideId');
    _socket?.emit('cancel_ride', {'rideId': rideId, 'reason': reason ?? 'Rider cancelled'});
    _socket?.emit('rider:cancel_ride', {'rideId': rideId, 'reason': reason ?? 'Rider cancelled'});
  }

  /// Disconnect socket client completely
  void disconnect() {
    print('🔌 [Socket] Disconnecting socket...');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentJoinedRideId = null;
  }

  void dispose() {
    disconnect();
    _locationUpdateController.close();
    _rideStatusController.close();
    _connectionStateController.close();
  }
}
