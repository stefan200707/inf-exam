#pragma once
#include <vector>
#include <memory>
#include <string>
#include "OrderItem.h"
#include "PaymentStrategy.h"

class PaymentStrategy; // forward

class Order {
private:
    int order_id_{};
    int user_id_{};
    std::string status_;
    std::vector<OrderItem> items_;
    std::unique_ptr<PaymentStrategy> payment_;

public:
    Order(int orderId, int userId, std::string status); // ✅ только объявление
    ~Order(); // ✅ тоже только объявление

    int id() const { return order_id_; }
    int userId() const { return user_id_; }
    const std::string& status() const { return status_; }
    void setStatus(std::string st) { status_ = std::move(st); }

    void addItem(const OrderItem& item) { items_.push_back(item); }
    const std::vector<OrderItem>& items() const { return items_; }

    void setPayment(std::unique_ptr<PaymentStrategy> pay) {
        payment_ = std::move(pay);
    }
};
