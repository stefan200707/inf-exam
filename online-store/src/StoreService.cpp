#include "StoreService.h"
#include <sstream>

StoreService::StoreService(DatabaseConnection<std::string>& db) : db_(db) {}

std::vector<std::vector<std::string>> StoreService::listProducts() {
    return db_.executeQuery(
        "SELECT product_id, name, price, stock_quantity "
        "FROM products ORDER BY product_id"
    );
}

// ✅ Новый метод
std::vector<Product> StoreService::getProducts() {
    auto rows = db_.executeQuery(
        "SELECT product_id, name, price, stock_quantity "
        "FROM products ORDER BY product_id"
    );

    std::vector<Product> products;
    products.reserve(rows.size());

    for (auto& r : rows) {
        Product p;
        p.id = std::stoi(r[0]);
        p.name = r[1];
        p.price = std::stod(r[2]);
        p.stock = std::stoi(r[3]);
        products.push_back(std::move(p));
    }

    return products;
}

int StoreService::createOrder(int userId,
                              const std::vector<int>& productIds,
                              const std::vector<int>& quantities) {
    if (productIds.empty() || quantities.empty() || productIds.size() != quantities.size())
        throw std::runtime_error("Invalid product list");

    std::ostringstream sql;
    sql << "CALL createOrder(" << userId << ", ARRAY[";

    for (size_t i = 0; i < productIds.size(); ++i) {
        if (i) sql << ",";
        sql << productIds[i];
    }
    sql << "], ARRAY[";

    for (size_t i = 0; i < quantities.size(); ++i) {
        if (i) sql << ",";
        sql << quantities[i];
    }
    sql << "]);";

    db_.executeNonQuery(sql.str());

    auto rows = db_.executeQuery(
        "SELECT order_id FROM orders "
        "WHERE user_id = " + std::to_string(userId) +
        " ORDER BY order_id DESC LIMIT 1;"
    );

    if (rows.empty()) return -1;
    return std::stoi(rows[0][0]);
}
