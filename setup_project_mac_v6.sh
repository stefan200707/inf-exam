#!/usr/bin/env bash
set -euo pipefail

# ===========================
# PROJECT
# ===========================
PROJECT_NAME="online-store"

# ===========================
# POSTGRES (use same as pgAdmin server connection)
# ===========================
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="postgres"
DB_PASS="stef4587"
DB_NAME="store_exam"

# used everywhere in C++
CONN_STR="host=${DB_HOST} port=${DB_PORT} dbname=${DB_NAME} user=${DB_USER} password=${DB_PASS}"

# ===========================
# HELPERS
# ===========================
say(){ printf "\n\033[1;32m==>\033[0m %s\n" "$1"; }
warn(){ printf "\n\033[1;33m[WARN]\033[0m %s\n" "$1"; }
err(){ printf "\n\033[1;31m[ERROR]\033[0m %s\n" "$1"; exit 1; }

need_cmd(){ command -v "$1" >/dev/null 2>&1; }

brew_install_if_missing(){
  local pkg="$1"
  if brew list "$pkg" >/dev/null 2>&1; then
    say "brew: $pkg already installed"
  else
    say "brew: installing $pkg ..."
    brew install "$pkg"
  fi
}

# ---- no sudo
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  err "Не запускай через sudo. Запуск: ./setup_project_mac_v6.sh"
fi

need_cmd brew || err "Homebrew не найден. Установи: https://brew.sh"

# ===========================
# DEPENDENCIES
# ===========================
say "Installing dependencies..."
brew_install_if_missing postgresql
brew_install_if_missing libpq
brew_install_if_missing libpqxx
brew_install_if_missing cmake
brew_install_if_missing pkg-config

BREW_PREFIX="$(brew --prefix)"
export PATH="$BREW_PREFIX/bin:$PATH"

# pkg-config must see libpq + libpqxx
export PKG_CONFIG_PATH="$BREW_PREFIX/opt/libpq/lib/pkgconfig:$BREW_PREFIX/lib/pkgconfig:$BREW_PREFIX/share/pkgconfig"
PKG_CONFIG_BIN="$BREW_PREFIX/bin/pkg-config"

"$PKG_CONFIG_BIN" --modversion libpq   >/dev/null || err "pkg-config can't see libpq"
"$PKG_CONFIG_BIN" --modversion libpqxx >/dev/null || err "pkg-config can't see libpqxx"

say "libpq version:   $("$PKG_CONFIG_BIN" --modversion libpq)"
say "libpqxx version: $("$PKG_CONFIG_BIN" --modversion libpqxx)"

# ===========================
# CREATE PROJECT
# ===========================
say "Creating project folder..."
rm -rf "$PROJECT_NAME"
mkdir -p "$PROJECT_NAME"/{include,src,sql,reports,build}

# ===========================
# SQL
# ===========================
say "Writing SQL..."

cat > "$PROJECT_NAME/sql/00_tables.sql" <<'EOF'
CREATE TABLE IF NOT EXISTS users (
  user_id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(150) UNIQUE NOT NULL,
  role VARCHAR(20) NOT NULL CHECK (role IN ('admin','manager','customer')),
  password_hash VARCHAR(255) NOT NULL,
  loyalty_level INT NOT NULL DEFAULT 0 CHECK (loyalty_level IN (0,1))
);

CREATE TABLE IF NOT EXISTS products (
  product_id SERIAL PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  price NUMERIC(12,2) NOT NULL CHECK (price > 0),
  stock_quantity INT NOT NULL CHECK (stock_quantity >= 0)
);

CREATE TABLE IF NOT EXISTS orders (
  order_id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES users(user_id),
  status VARCHAR(20) NOT NULL CHECK (status IN ('pending','paid','completed','canceled','returned')),
  total_price NUMERIC(12,2) NOT NULL DEFAULT 0,
  order_date TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS order_items (
  order_item_id SERIAL PRIMARY KEY,
  order_id INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
  product_id INT NOT NULL REFERENCES products(product_id),
  quantity INT NOT NULL CHECK(quantity > 0),
  price NUMERIC(12,2) NOT NULL CHECK(price > 0)
);

CREATE TABLE IF NOT EXISTS audit_log (
  log_id SERIAL PRIMARY KEY,
  entity_type VARCHAR(20) NOT NULL CHECK(entity_type IN ('order','product','user','payment')),
  entity_id INT NOT NULL,
  operation VARCHAR(20) NOT NULL CHECK(operation IN ('insert','update','delete','error','info')),
  performed_by INT,
  performed_at TIMESTAMP NOT NULL DEFAULT NOW(),
  details TEXT
);
EOF

cat > "$PROJECT_NAME/sql/01_sample_data.sql" <<'EOF'
INSERT INTO users(name,email,role,password_hash,loyalty_level)
VALUES
('Admin','admin@mail.com','admin','hash',1),
('Manager','manager@mail.com','manager','hash',0),
('Customer','cust@mail.com','customer','hash',0)
ON CONFLICT DO NOTHING;

INSERT INTO products(name,price,stock_quantity)
VALUES
('Laptop',1200.00,10),
('Mouse',25.00,100),
('Keyboard',55.50,50),
('Monitor',230.00,20)
ON CONFLICT DO NOTHING;
EOF

# ===========================
# C++ (pqxx::connection everywhere)
# ===========================
say "Writing C++..."

cat > "$PROJECT_NAME/include/StoreService.h" <<'EOF'
#pragma once
#include <pqxx/pqxx>
#include <vector>
#include <string>

class StoreService {
public:
  explicit StoreService(pqxx::connection& conn);
  std::vector<std::vector<std::string>> listProducts();

private:
  pqxx::connection& conn_;
};
EOF

cat > "$PROJECT_NAME/src/StoreService.cpp" <<'EOF'
#include "StoreService.h"

StoreService::StoreService(pqxx::connection& conn) : conn_(conn) {}

std::vector<std::vector<std::string>> StoreService::listProducts() {
  pqxx::work tx(conn_);
  pqxx::result r = tx.exec("SELECT product_id, name, price, stock_quantity FROM products ORDER BY product_id");
  tx.commit();

  std::vector<std::vector<std::string>> out;
  for (auto row : r) {
    std::vector<std::string> line;
    for (auto f : row) line.push_back(f.c_str());
    out.push_back(std::move(line));
  }
  return out;
}
EOF

cat > "$PROJECT_NAME/src/main.cpp" <<EOF
#include <iostream>
#include <pqxx/pqxx>
#include "StoreService.h"

int main() {
  try {
    pqxx::connection conn{"$CONN_STR"};

    StoreService service(conn);
    auto rows = service.listProducts();

    std::cout << "Products:\\n";
    for (auto& r : rows) {
      for (auto& x : r) std::cout << x << " ";
      std::cout << "\\n";
    }

    std::cout << "\\nDB OK ✅\\n";
  } catch (const std::exception& e) {
    std::cerr << "DB ERROR: " << e.what() << "\\n";
    return 1;
  }
  return 0;
}
EOF

# ✅ FIXED CMakeLists (imported target)
cat > "$PROJECT_NAME/CMakeLists.txt" <<'EOF'
cmake_minimum_required(VERSION 3.16)
project(online_store_exam)

set(CMAKE_CXX_STANDARD 17)
include_directories(include)

find_package(PkgConfig REQUIRED)

# ✅ important fix: imported target for macOS/Homebrew
pkg_check_modules(PQXX REQUIRED IMPORTED_TARGET libpqxx)

add_executable(online_store
  src/main.cpp
  src/StoreService.cpp
)

target_link_libraries(online_store PRIVATE PkgConfig::PQXX)
EOF

# ===========================
# DB SETUP
# ===========================
say "Checking PostgreSQL login..."
export PGPASSWORD="$DB_PASS"

psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "SELECT 1;" >/dev/null \
  || err "Не могу подключиться к Postgres как '${DB_USER}'. Проверь пароль/права в pgAdmin."

say "Creating DB '${DB_NAME}' if missing..."
DB_EXISTS=$(
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc \
    "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}';" || true
)

if [[ "$DB_EXISTS" != "1" ]]; then
  say "Database not found -> creating..."
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -v ON_ERROR_STOP=1 \
    -c "CREATE DATABASE ${DB_NAME};"
else
  say "Database already exists"
fi

say "Applying SQL..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f "$PROJECT_NAME/sql/00_tables.sql"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f "$PROJECT_NAME/sql/01_sample_data.sql"

# ===========================
# BUILD
# ===========================
say "Building project..."
cmake -S "$PROJECT_NAME" -B "$PROJECT_NAME/build" -DCMAKE_BUILD_TYPE=Release
cmake --build "$PROJECT_NAME/build" -j

say "DONE ✅"
echo "Run:"
echo "./$PROJECT_NAME/build/online_store"

