#pragma once
#include <pqxx/pqxx>
#include <memory>
#include <string>
#include <vector>

template<typename T>
class DatabaseConnection {
public:
    explicit DatabaseConnection(const T& connStr)
        : conn_(std::make_unique<pqxx::connection>(connStr)) {}

    ~DatabaseConnection() {
        rollbackTransaction(); // на всякий случай
        conn_.reset();
    }

    // SELECT запросы
    std::vector<std::vector<std::string>> executeQuery(const std::string& sql) {
        pqxx::work w(*conn_);
        auto r = w.exec(sql);
        w.commit();

        std::vector<std::vector<std::string>> out;
        for (auto row : r) {
            std::vector<std::string> line;
            for (auto field : row) line.push_back(field.c_str());
            out.push_back(std::move(line));
        }
        return out;
    }

    // INSERT/UPDATE/DELETE
    void executeNonQuery(const std::string& sql) {
        pqxx::work w(*conn_);
        w.exec(sql);
        w.commit();
    }

    // ===== Transaction control =====

    void beginTransaction() {
        if (tx_) throw std::runtime_error("Transaction already started");
        tx_ = std::make_unique<pqxx::work>(*conn_);
    }

    void commitTransaction() {
        if (!tx_) throw std::runtime_error("No active transaction");
        tx_->commit();
        tx_.reset();
    }

    void rollbackTransaction() {
        // pqxx откатывает транзакцию при уничтожении объекта work без commit()
        tx_.reset();
    }

    // доступ к активной транзакции (если нужна)
    pqxx::work& transaction() {
        if (!tx_) throw std::runtime_error("No active transaction");
        return *tx_;
    }

    // доступ к raw connection (если где-то надо)
    pqxx::connection& raw() { return *conn_; }

private:
    std::unique_ptr<pqxx::connection> conn_;
    std::unique_ptr<pqxx::work> tx_;
};
