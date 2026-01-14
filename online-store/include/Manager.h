#pragma once
#include "User.h"

class Manager : public User {
public:
    Manager(int id, std::string name)
        : User(id, std::move(name), "manager") {}

    void showMenu() override;
};
