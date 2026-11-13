import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  IO.Socket? _socket;
  bool get isConnected => _socket?.connected ?? false;

  SocketService._internal();

  void initSocket() async {
    final token = await SecureStorageService.getToken();
    final userId = await SecureStorageService.getUserId();

    _socket = IO.io(
      ApiConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket?.onConnect((_) {
      if (userId != null) {
        _socket?.emit('join_user_room', userId);
      }
    });
  }

  void joinTripRoom(String tripId) {
    _socket?.emit('join_trip_room', tripId);
  }

  void leaveTripRoom(String tripId) {
    _socket?.emit('leave_trip_room', tripId);
  }

  void onGroupExpenseAdded(Function(dynamic data) callback) {
    _socket?.on('trip_expense_added', callback);
  }

  void onSettlementUpdated(Function(dynamic data) callback) {
    _socket?.on('settlement_updated', callback);
  }

  void disconnect() {
    _socket?.disconnect();
  }
}
