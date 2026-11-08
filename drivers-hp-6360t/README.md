# Drivers HP 6360t (Windows 11 Pro)

Copia de respaldo de los drivers de terceros que usa mi HP 6360t
(ProBook 6360b / SKU LJ479UT#ABA, Core i5-2540M, Intel HD Graphics 3000),
exportados desde el sistema funcionando con:

```
pnputil /export-driver * <carpeta>
```

Solo incluye los drivers de hardware de la laptop. No incluye drivers
integrados de Windows ni software de terceros (Parsec, impresoras, etc.).

| Carpeta | Dispositivo | Versión (fecha) |
|---|---|---|
| `stwrt64.inf_amd64_*` | Audio IDT 92HD81B1C (versión parcheada, ver abajo) | 6.10.6498.0 (2013-12-05) |
| `igdlh64.inf_amd64_*` | Intel HD Graphics 3000 (video) | 9.17.10.4459 (2016-05-19) |
| `synpd.inf_amd64_*` | Touchpad Synaptics | 19.0.12.0 (2015-06-11) |
| `e1c64x64.inf_amd64_*` | Ethernet Intel 82579V | 12.10.29.0 (2014-05-02) |
| `heci.inf_amd64_*` | Intel Management Engine Interface | 11.0.0.1157 (2015-07-07) |
| `cougarpointsystem.inf_amd64_*` | Chipset Intel 6 Series (Cougar Point) | 10.1.1.38 (2016-10-03) |
| `cougarpointusb.inf_amd64_*` | Controladores USB Intel 6 Series | 10.1.1.38 (2016-10-03) |
| `sandybridgesystem.inf_amd64_*` | Intel Sandy Bridge (sistema) | 10.1.1.38 (2016-10-03) |
| `jmcr_hp_no_mmc.inf_amd64_*` | Lector de tarjetas JMicron | 1.0.76.1 (2013-04-26) |
| `accelerometer.inf_amd64_*` | HP Mobile Data Protection Sensor | 4.2.9.1 (2012-09-24) |

El driver de audio IDT de esta carpeta es el instalado actualmente: la
versión parcheada (firmada con certificado de prueba) para el LED del botón
de silencio. Sus fuentes y el instalador están en `../driver` y en el
README de la raíz; ese driver requiere el modo de firma de prueba
(`bcdedit /set testsigning on`).

## Instalar

Como administrador, en la carpeta del driver que quieras:

```
pnputil /add-driver *.inf /install
```

o todos a la vez desde esta carpeta:

```
pnputil /add-driver *\*.inf /subdirs /install
```

## Aviso

Son binarios de sus fabricantes (Intel, Synaptics, IDT, JMicron, HP) y
conservan sus licencias originales. Se guardan como respaldo personal para
este equipo.
