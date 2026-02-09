# Ledger

Aplicación CLI desarrollada en **Elixir** para la gestión de usuarios, cuentas y transacciones, ejecutada.

---

## Requisitos

* Docker
* Docker Compose

---

## Clonar el repositorio

```bash
git clone <url-del-repositorio>
cd ledger
```

---

## Instalación de dependencias (local)

```bash
mix deps.get
```

---

## Build de la imagen

```bash
docker compose build --no-cache
```

---

## Levantar servicios

```bash
docker compose up -d
```

---

## Ejecución de comandos

La aplicación se ejecuta como una **CLI** dentro del contenedor.

Ejemplo:

```bash
docker compose run --rm app ./ledger ver_usuario -id=1
```

---

## Alias (Recomendacion, opcional – Linux / macOS / WSL)

Para evitar escribir el comando completo en cada ejecución, se puede crear un alias:

```bash
alias ledger="docker compose run --rm -q app ./ledger"
```

Luego ejecutar directamente:

```bash
ledger ver_usuario -id=1
```

> ⚠️ El alias funciona únicamente en shells tipo Unix (bash, zsh, etc.).
> En Windows sin WSL, debe usarse el comando completo.

---

## Ejecución de tests

Los tests se ejecutan dentro de Docker utilizando el entorno `test`.

```bash
docker compose run --rm -e MIX_ENV=test app mix test --cover
```

Esto garantiza:

* Base de datos aislada para testing
* Uso de `Ecto.Adapters.SQL.Sandbox`
