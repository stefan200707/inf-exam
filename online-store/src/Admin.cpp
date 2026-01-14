#include "../include/Admin.h"
#include <iostream>

void Admin::showMenu() {
    std::cout << "\n[ADMIN MENU]\n";
    std::cout << "1) View products\n";
    std::cout << "2) View all audit logs\n";
    std::cout << "3) Export report CSV\n";
    std::cout << "0) Exit\n";
}