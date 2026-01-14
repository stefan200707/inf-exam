#pragma once
#include "User.h"

class Admin : public User {
public:
    Admin(int id, std::string name)
        : User(id, std::move(name), "admin") {}

    void showMenu() override;
};
