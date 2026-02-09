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
cd ledger_tp2
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

docker compose exec app mix ecto.create

docker compose exec app mix ecto.migrate

```

---

## Ejecución de comandos

La aplicación se ejecuta como una **CLI** dentro del contenedor.

Ejemplo:

```bash
docker compose exec app ./ledger crear_usuario -n=LionelMessi -b=1987-06-24
```

---

## Alias (Recomendacion, opcional – Linux / macOS / WSL)

Para evitar escribir el comando completo en cada ejecución, se puede crear un alias:

```bash
alias ledger="docker compose exec app ./ledger"
```

Luego ejecutar directamente:

```bash
ledger crear_usuario -n=LionelMessi -b=1987-06-24
```

---

## Ejecución de tests

Los tests se ejecutan dentro de Docker utilizando el entorno `test`.

```bash
docker compose exec -e MIX_ENV=test app mix ecto.create

docker compose exec -e MIX_ENV=test app mix ecto.migrate

docker compose exec -e MIX_ENV=test app mix test --cover
```

Esto garantiza:

* Base de datos aislada para testing
* Uso de `Ecto.Adapters.SQL.Sandbox`
