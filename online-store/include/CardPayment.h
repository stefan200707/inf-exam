#pragma once
#include "PaymentStrategy.h"
#include <iostream>

class CardPayment : public PaymentStrategy {
public:
    bool pay(double amount) override {
        std::cout << "[Card] Payment processed: " << amount << "\n";
        return true;
    }
};
