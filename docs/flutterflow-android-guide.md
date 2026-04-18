# FlutterFlow - App Android ColmadoAI

> Guide para implementar la app Android de impresión de tickets

---

## Configuración Inicial

### 1. Crear proyecto
1. Ir a [FlutterFlow](https://flutterflow.io)
2. Click "Start New Project"
3. Nombre: "ColmadoAI Impresora"
4. Seleccionar "Android"

### 2. Conectar Convex SDK

En FlutterFlow:
1. Ir a **Settings** → **Backend Connections**
2. Click **Add Backend** → **Convex**
3. Ingresar:
   - **Convex Deployment URL**: `https://tu-proyecto.convex.cloud`
   - **Convex Deployment Key**: obtener de `npx convex deploy`
4. Click **Connect**

### 3. Agregar Convex SDK Dependency

En **Settings** → **Pub Spec**:
```yaml
dependencies:
  convex_flutter: ^0.1.0
```

---

## Estructura de Pages

### Page 1: Home (Orders List)

**Widgets:**
- AppBar con título "Órdenes Pendientes"
- Stream Builder (query: ordenes con estado "lista_para_imprimir")
- ListView con OrderCard widgets
- Pull-to-refresh

**OrderCard Widget:**
- Card con info de orden
- Mostrar: ID, cliente, total, hora
- Botón "Imprimir" (icon button)
- States: loading, success, error

### Page 2: Order Detail (opcional)

- Ver todos los productos de la orden
- Notas adicionales
- Botón grande "IMPRIMIR"

---

## Custom Actions (Código Flutter)

### Custom Action 1: Conectar Impresora

```dart
// Nombre: connectToPrinter
// Tipo: Flutter Custom Code

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

Future<String?> connectToPrinter() async {
  final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
  
  // Buscar impresora por nombre (ajustar)
  final printer = devices.firstWhere(
    (d) => d.name.contains('Thermal') || d.name.contains('Printer'),
    orElse: () => devices.first,
  );
  
  final connection = await BluetoothConnection.toAddress(printer.address);
  return connection.isConnected ? printer.address : null;
}
```

### Custom Action 2: Imprimir Ticket

```dart
// Nombre: printTicket
// Tipo: Flutter Custom Code
// Input: orderData (JSON), printerAddress (String)

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:typed_data';

Future<bool> printTicket(Map orderData, String printerAddress) async {
  // Construir ticket ESC/POS
  final ticket = _buildTicket(orderData);
  
  // Conectar e imprimir
  final connection = await BluetoothConnection.toAddress(printerAddress);
  
  await connection.output.add(Uint8List.fromList(ticket));
  await connection.finish();
  
  return true;
}

List<int> _buildTicket(Map order) {
  // ESC/POS commands
  List<int> bytes = [];
  
  // Initialize printer
  bytes.addAll([0x1B, 0x40]); // ESC @
  
  // Center align
  bytes.addAll([0x1B, 0x61, 0x01]); // ESC a 1
  
  // Title (store name)
  bytes.addAll(_textToBytes("COLMADO AI\n"));
  bytes.addAll([0x1B, 0x45, 0x01]); // Bold on
  bytes.addAll(_textToBytes("================================\n"));
  bytes.addAll([0x1B, 0x45, 0x00]); // Bold off
  
  // Order info
  bytes.addAll(_textToBytes("Orden #: ${order['id']}\n"));
  bytes.addAll(_textToBytes("Fecha: ${order['fecha']}\n"));
  
  // Products
  bytes.addAll([0x1B, 0x61, 0x00]); // Left align
  bytes.addAll(_textToBytes("--------------------------------\n"));
  
  for (var product in order['productos']) {
    bytes.addAll(_textToBytes(
      "${product['nombre']}\n"
      "  x${product['cantidad']}   RD\$${product['precio']}\n"
    ));
  }
  
  bytes.addAll(_textToBytes("--------------------------------\n"));
  
  // Total (bold)
  bytes.addAll([0x1B, 0x45, 0x01]);
  bytes.addAll(_textToBytes("TOTAL: RD\$${order['total']}\n"));
  bytes.addAll([0x1B, 0x45, 0x00]);
  
  // Cut paper
  bytes.addAll([0x1D, 0x56, 0x00]); // GS V 0 (full cut)
  
  return bytes;
}

List<int> _textToBytes(String text) {
  // Convertir texto a bytes, manejando ñ y caracteres especiales
  return text.codeUnits;
}
```

### Custom Action 3: Actualizar Estado

```dart
// Nombre: updateOrderStatus
// Llama a Convex mutation: actualizarEstadoOrden

// En FlutterFlow: usar Action "Run Convex Mutation"
```

---

## Queries a configurar en FlutterFlow

| Query Name | Backend Query | Description |
|------------|---------------|-------------|
| getOrdenPending | `getOrdenPorEstado(estado: "lista_para_imprimir")` | Órdenes pendientes |
| getOrdenById | `getOrdenById(ordenId)` | Detalle de orden |

---

## Actions en FlutterFlow

### On Tap "Imprimir" button:

1. **Custom Action**: `connectToPrinter`
   - Si falla → Mostrar snackbar "Impresora no conectada"

2. **Custom Action**: `printTicket`
   - Input: `selectedOrder.toJson()`, `printerAddress`
   - Si falla → Mostrar snackbar "Error al imprimir"

3. **Convex Mutation**: `actualizarEstadoOrden`
   - Arguments: `ordenId: selectedOrder._id`, `estado: "impresa"`

4. **Refresh**: Recargar lista de órdenes

---

## Testing

1. **Emparejar impresora**: En Android, Settings → Bluetooth
2. **Probar en dispositivo**: Usar "Run on Device" en FlutterFlow
3. **Test completo**:
   - Crear orden en dashboard → Aparece en app
   - Click "Imprimir" → Ticket sale
   - Estado cambia a "impresa" en dashboard

---

## APK Build

En FlutterFlow:
1. Click **Publish** → **Build APK**
2. Descargar APK
3. Instalar en dispositivo Android
4. Empujar desde PC: `adb install app.apk`