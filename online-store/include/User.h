#pragma once
#include <string>
#include <vector>
#include <memory>
#include "Order.h"

class User {
protected:
    int id_;
    std::string name_;
    std::string role_;

    // ✅ агрегация: пользователь "имеет" заказы
    std::vector<std::shared_ptr<Order>> orders_;

public:
    User(int id, std::string name, std::string role)
        : id_(id), name_(std::move(name)), role_(std::move(role)) {}

    virtual ~User() = default;

    int id() const { return id_; }
    const std::string& name() const { return name_; }
    const std::string& role() const { return role_; }

    const std::vector<std::shared_ptr<Order>>& orders() const { return orders_; }
    void addOrder(std::shared_ptr<Order> ord) { orders_.push_back(std::move(ord)); }

    virtual void showMenu() = 0; // ✅ чисто виртуальная
};
