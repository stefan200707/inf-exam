#pragma once
#include "PaymentStrategy.h"
#include <iostream>

class WalletPayment : public PaymentStrategy {
public:
    bool pay(double amount) override {
        std::cout << "[Wallet] Payment processed: " << amount << "\n";
        return true;
    }
};
