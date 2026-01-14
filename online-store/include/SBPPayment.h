#pragma once
#include "PaymentStrategy.h"
#include <iostream>

class SBPPayment : public PaymentStrategy {
public:
    bool pay(double amount) override {
        std::cout << "[SBP] Payment processed: " << amount << "\n";
        return true;
    }
};
