#include "Order.h"
#include "PaymentStrategy.h"

Order::Order(int orderId, int userId, std::string status)
    : order_id_(orderId),
      user_id_(userId),
      status_(std::move(status)) {}

Order::~Order() = default;
