#include "Customer.h"
#include <iostream>

void Customer::showMenu() {
    std::cout << "\n[CUSTOMER MENU]\n";
    std::cout << "1) View products\n";
    std::cout << "2) Create order\n";
    std::cout << "0) Exit\n";
}
