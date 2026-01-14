#pragma once
#include "User.h"

class Customer : public User {
public:
    Customer(int id, std::string name)
        : User(id, std::move(name), "customer") {}

    void showMenu() override;
};
