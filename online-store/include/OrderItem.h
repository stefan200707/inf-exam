#pragma once
#include "Product.h"

struct OrderItem {
    Product product;   // ✅ композиция: item содержит продукт
    int quantity{};
};
