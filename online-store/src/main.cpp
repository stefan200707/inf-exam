#include <iostream>
#include <memory>
#include <vector>
#include <string>
#include <algorithm>
#include <numeric>

#include "DatabaseConnection.h"
#include "StoreService.h"
#include "ReportService.h"

#include "User.h"
#include "Admin.h"
#include "Manager.h"
#include "Customer.h"

#include "OrderItem.h"

#include "PaymentStrategy.h"
#include "CardPayment.h"
#include "WalletPayment.h"
#include "SBPPayment.h"

static std::unique_ptr<User> login() {
    int choice;
    std::cout << "Choose role:\n";
    std::cout << "1) Admin\n";
    std::cout << "2) Manager\n";
    std::cout << "3) Customer\n";
    std::cout << "Enter: ";
    std::cin >> choice;

    if (choice == 1) return std::make_unique<Admin>(1, "Admin");
    if (choice == 2) return std::make_unique<Manager>(2, "Manager");
    return std::make_unique<Customer>(3, "Customer");
}

static void showProductsWithAlgorithms(StoreService& service) {
    auto products = service.getProducts();

    std::vector<Product> available;
    std::copy_if(products.begin(), products.end(), std::back_inserter(available),
                 [](const Product& p) { return p.stock > 0; });

    std::cout << "\nAvailable products:\n";
    for (const auto& p : available) {
        std::cout << p.id << ") " << p.name
                  << " price=" << p.price
                  << " stock=" << p.stock << "\n";
    }
}

int main() {
    try {
        DatabaseConnection<std::string> db(
            "host=localhost port=5432 dbname=store_exam user=postgres password=stef4587"
        );

        StoreService service(db);
        ReportService reports(db);

        auto user = login();

        while (true) {
            user->showMenu();

            int cmd;
            std::cout << "Command: ";
            std::cin >> cmd;

            if (cmd == 0) break;

            // 1) Products list
            if (cmd == 1) {
                showProductsWithAlgorithms(service);
                continue;
            }

            // 2) Customer: create order + pay
            if (cmd == 2 && user->role() == "customer") {
                int productId, qty;
                std::cout << "Enter product_id: ";
                std::cin >> productId;
                std::cout << "Enter quantity: ";
                std::cin >> qty;

                auto products = service.getProducts();

                auto it = std::find_if(products.begin(), products.end(),
                                       [productId](const Product& p) {
                                           return p.id == productId;
                                       });

                if (it == products.end()) {
                    std::cout << "Product not found ❌\n";
                    continue;
                }
                if (it->stock < qty) {
                    std::cout << "Not enough stock ❌\n";
                    continue;
                }

                std::vector<OrderItem> items;
                items.push_back(OrderItem{*it, qty});

                double localTotal = std::accumulate(items.begin(), items.end(), 0.0,
                    [](double sum, const OrderItem& item) {
                        return sum + item.product.price * item.quantity;
                    }
                );

                std::cout << "Local calculated total: " << localTotal << "\n";

                int payChoice;
                std::cout << "Payment method:\n";
                std::cout << "1) Card\n";
                std::cout << "2) Wallet\n";
                std::cout << "3) SBP\n";
                std::cout << "Enter: ";
                std::cin >> payChoice;

                std::unique_ptr<PaymentStrategy> strategy;
                if (payChoice == 1) strategy = std::make_unique<CardPayment>();
                else if (payChoice == 2) strategy = std::make_unique<WalletPayment>();
                else strategy = std::make_unique<SBPPayment>();

                int orderId = service.createOrder(user->id(), {productId}, {qty});

                auto totalRows = db.executeQuery(
                    "SELECT total_price FROM orders WHERE order_id=" + std::to_string(orderId) + ";"
                );
                double totalDb = totalRows.empty() ? 0.0 : std::stod(totalRows[0][0]);

                if (strategy->pay(totalDb)) {
                    db.executeNonQuery(
                        "CALL updateOrderStatus(" +
                        std::to_string(orderId) + ", 'paid', " + std::to_string(user->id()) + ");"
                    );
                    std::cout << "Order paid ✅ order_id=" << orderId << "\n";
                } else {
                    std::cout << "Payment failed ❌\n";
                }

                continue;
            }

            // 3) Admin: export CSV report
            if (cmd == 3 && user->role() == "admin") {
                reports.exportAuditReportCSV("reports/audit_report.csv");
                continue;
            }

            std::cout << "Not implemented for this role.\n";
        }

    } catch (const std::exception& e) {
        std::cerr << "FATAL ERROR: " << e.what() << "\n";
        return 1;
    }

    return 0;
}
