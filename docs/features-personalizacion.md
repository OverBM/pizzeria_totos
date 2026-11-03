# Personalización, cupones y planes

## Pizza personalizada

- `configuracion/pizzaPersonalizada` define tamaños, masas, salsas, quesos,
  minutos y capacidad por defecto.
- `ingredientes/{id}` contiene los toppings y su precio base.
- El precio se calcula en céntimos con `Money.toCents`/`fromCents` y se guarda
  como `double` en soles. No se crea un campo paralelo en céntimos.
- La base incluye masa, salsa y queso estándar. «Sin queso» resta el valor
  configurado con piso en cero.
- El ETA usa `carga = Σ peso(tamaño)` (0.5/1.0/1.5), `lotes =
  ceil(carga/capacidadHorno)`, `prep = lotes×tiempoLote +
  (lotes−1)×recuperacionMin` y suma 5 min si `medidoEn` es null.
- `sedes/{id}` puede sobrescribir `capacidadHorno`, `recuperacionMin` y
  `medidoEn`; si faltan, se usan 4, 0 y null.

## Cupones

- Documento: `cupones/{codigo}`. Solo `get` por código; nunca listado.
- El código se busca exactamente como fue escrito (distingue mayúsculas).
- `compraMinima` se evalúa sobre el subtotal después de promociones.
- `maxUsos` es global y `redenciones/{codigo}_{uid}` garantiza una redención
  por usuario.
- El pedido se crea en una transacción con el incremento de `usos` y la
  redención. Si falla, no se consume el cupón.

## Planes

- `planesDelivery/{id}` solo contiene La Previa (30 días, S/ 14.90) y La Fija
  (90 días, S/ 39.90).
- El Antojo no es un plan: es la etiqueta de ausencia de suscripción y su copy
  e imagen viven en `configuracion/planBase`.
- El envío gratis exige delivery dentro de cobertura y una compra mínima de
  S/ 20.00 en La Previa o S/ 15.00 en La Fija, sobre el subtotal después de
  promociones y antes del cupón.
- `suscripciones/{uid}` guarda la vigencia, `enviosUsados`, cancelación y
  `renuevaAutomatico: false`. `enviosUsados` se incrementa en la misma
  transacción que crea el pedido.

## Imágenes

Las fotos de El Antojo, La Previa y La Fija se suben a Drive y se referencian
con `MediaRef` (`driveId`). Si faltan o no son públicas, la app usa
`assets/icons/plans/*.svg` como respaldo.
