# Online Store (Exam Project 2025) — C++ + PostgreSQL

Проект интернет-магазина, реализованный на **C++17** (ООП, STL, умные указатели) и **PostgreSQL** (таблицы, функции, процедуры, триггеры, транзакции).
В проекте реализованы роли пользователей (Admin/Manager/Customer), логика заказов и выгрузка отчёта в CSV.

---

## 1) Технологии

- **C++17**
- **PostgreSQL**
- **libpqxx** — C++ клиент для PostgreSQL
- **CMake**
- **pgAdmin** (для выполнения SQL)

---

## 2) Структура проекта

```
online-store/
  include/                 # заголовочные файлы (.h)
  src/                     # исходники (.cpp)
  sql/                     # SQL-скрипты БД
    00_tables.sql
    01_functions.sql
    02_procedures.sql
    03_triggers.sql
    04_sample_data.sql
  reports/                 # CSV отчёты (создаётся автоматически при экспорте)
  CMakeLists.txt
  README.md
```

---

## 3) База данных PostgreSQL

### 3.1 Таблицы (6 шт.)

- `users` — пользователи системы (роль admin/manager/customer)
- `products` — товары
- `orders` — заказы
- `order_items` — позиции заказа
- `order_status_history` — история изменения статусов заказов (обязательная)
- `audit_log` — аудит действий пользователей

Создание таблиц: `sql/00_tables.sql`

---

## 4) PostgreSQL функции (`sql/01_functions.sql`)

Реализованы функции:

- `getOrderStatus(order_id)`
- `getUserOrderCount()`
- `getTotalSpentByUser(user_id)`
- `canReturnOrder(order_id)` — возврат возможен только если completed и прошло ≤ 30 дней
- `getOrderStatusHistory(order_id)`
- `getAuditLogByUser(user_id)`

---

## 5) PostgreSQL процедуры (`sql/02_procedures.sql`)

Реализованы процедуры:

### `createOrder(user_id, product_ids[], quantities[])`
- создаёт заказ
- добавляет товары в заказ (`order_items`)
- уменьшает количество товара на складе
- пересчитывает `orders.total_price`
- пишет запись в `audit_log`

### `updateOrderStatus(order_id, new_status, changed_by)`
- меняет статус заказа
- пишет историю в `order_status_history`
- логирует действие в `audit_log`

---

## 6) PostgreSQL триггеры (`sql/03_triggers.sql`)

Реализованы триггеры:

1) **Update order_date**: если меняется статус заказа — обновляется `orders.order_date`
2) **Recalculate total_price**: если меняется цена товара — пересчитываются суммы заказов
3) **Auto status history**: если статус заказа меняется напрямую (не через процедуру) — запись добавляется в `order_status_history`

---

## 7) ООП: роли пользователей и полиморфизм

### Классы пользователей
- `User` — базовый класс, содержит чисто виртуальную функцию `showMenu()`
- `Admin`, `Manager`, `Customer` — наследники

### Полиморфизм
В `main.cpp` используется:
- `std::unique_ptr<User>` — хранение объекта пользователя

---

## 8) Smart pointers, композиция, агрегация

Используются:
- `std::unique_ptr`
- `std::shared_ptr`

Композиция:
- `Order` содержит `std::vector<OrderItem>`

Агрегация:
- `User` агрегирует заказы: `std::vector<std::shared_ptr<Order>>`

---

## 9) Шаблонный класс DatabaseConnection<T>

Реализован обязательный класс:
- `DatabaseConnection<T>`

Функциональность:
- выполнение SELECT (`executeQuery`)
- выполнение INSERT/UPDATE/DELETE (`executeNonQuery`)
- транзакции:
  - `beginTransaction()`
  - `commitTransaction()`
  - `rollbackTransaction()`

---

## 10) STL algorithms + lambdas

В проекте применяются STL алгоритмы:

- `std::copy_if` — фильтрация товаров в наличии
- `std::find_if` — поиск товара по `product_id`
- `std::accumulate` — расчёт суммы заказа

Используются лямбда-выражения в STL.

---

## 11) Strategy Pattern (оплата)

Интерфейс:
- `PaymentStrategy`

Реализации:
- `CardPayment`
- `WalletPayment`
- `SBPPayment`

Выбор стратегии оплаты производится в меню **Customer**.

---

## 12) CSV отчёт (только Admin)

Реализован экспорт отчёта:

- `ReportService::exportAuditReportCSV(...)`

Файл сохраняется в:

- `reports/audit_report.csv`

Примечание:
- папка `reports/` создаётся автоматически через `std::filesystem::create_directories(...)`
- экспорт доступен только пользователю роли **Admin**



---

## 13) Подключение к PostgreSQL

В `main.cpp` используется строка подключения:

```
host=localhost port=5432 dbname=store_exam user=postgres password=stef4587
```

(при необходимости заменить user/password на свои)

---

## 14) Роли и меню

- **Admin**
  - просмотр товаров
  - экспорт CSV отчёта

- **Manager**
  - просмотр товаров
  - (дополняется) управление статусами заказов

- **Customer**
  - просмотр товаров
  - создание заказа + выбор способа оплаты
