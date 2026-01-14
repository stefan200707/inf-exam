#pragma once
#include <string>
#include <vector>

#include "DatabaseConnection.h"
#include "Product.h"

class StoreService {
public:
    explicit StoreService(DatabaseConnection<std::string>& db);

    // старый вариант (можно оставить если где-то нужен)
    std::vector<std::vector<std::string>> listProducts();

    // ✅ новый: продукты как структуры Product (нужно для STL алгоритмов)
    std::vector<Product> getProducts();

    // создание заказа через SQL CALL createOrder(...)
    int createOrder(int userId,
                    const std::vector<int>& productIds,
                    const std::vector<int>& quantities);

private:
    DatabaseConnection<std::string>& db_;
};
