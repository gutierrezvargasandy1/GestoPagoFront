# GestoPago App (Flutter: web y movil)

Cliente Flutter del backend `pagos-servicios`. Un solo codigo para la version
web y la movil: login compartido, doble factor validado en el servidor, una
sola sesion activa por usuario, catalogo por categorias, compras y el historial
de compras exitosas.

## Encender

```powershell
cd C:\Users\andre\Desktop\gestopago_app
flutter pub get

# Contra el backend local (http://localhost:8080)
flutter run -d chrome --web-port 5000 --dart-define=API_URL=http://localhost:8080

# Contra Render (cuando ya este desplegado el backend con 2FA)
flutter run -d chrome --web-port 5000

# En el celular (Android, depuracion USB). Desde el emulador, localhost es 10.0.2.2
flutter run -d android --dart-define=API_URL=https://gestopago-pp6y.onrender.com
```

## Estructura

| Carpeta | Contenido |
|---|---|
| `lib/core` | Cliente HTTP (Bearer, errores ProblemDetail, cierre de sesion ante 401) y almacenamiento cifrado del token |
| `lib/servicios` | Una clase por grupo de endpoints: auth, catalogo, pagos |
| `lib/estado` | `SesionController`: estado de la sesion y el perfil |
| `lib/ui/pantallas` | Acceso (login, registro, 2FA), catalogo, compra, historial, cuenta |

## Endpoints que consume

| Metodo | Endpoint | Uso |
|---|---|---|
| POST | `/api/v1/auth/registro` | Crear cuenta |
| POST | `/api/v1/auth/token` | Paso 1: usuario y contrasena, devuelve el desafio |
| POST | `/api/v1/auth/2fa` | Paso 2: codigo de 6 digitos; 409 `SESION_ACTIVA` si hay otra sesion |
| POST | `/api/v1/auth/logout` | Cerrar sesion |
| GET | `/api/v1/perfil` | Nombre, cuenta, saldo y sesion |
| GET | `/api/v1/catalogo/servicios` | Servicios con su categoria |
| GET | `/api/v1/catalogo/servicios/{id}/productos` | Productos y si se pueden comprar |
| POST | `/api/v1/pagos` | Compra (con `Idempotency-Key`) |
| GET | `/api/v1/pagos/{id}` | Consultar una compra pendiente |
| GET | `/api/v1/pagos/historial` | Solo compras confirmadas |

## Seguridad en el cliente

- El token se guarda cifrado (`flutter_secure_storage`); la contrasena y el codigo nunca se guardan.
- Cualquier 401 cierra la sesion local y regresa al login con el motivo.
- La app no decide si una compra fue exitosa: solo muestra el estado que devuelve el servidor.
"# GestoPagoFront" 
