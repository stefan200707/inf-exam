#include "ReportService.h"
#include <fstream>
#include <iostream>
#include <filesystem>   // ✅ важно

// CSV escaping
static std::string csvEscape(const std::string& s) {
    bool needQuotes = false;
    for (char c : s) {
        if (c == ',' || c == '"' || c == '\n' || c == '\r') {
            needQuotes = true;
            break;
        }
    }
    if (!needQuotes) return s;

    std::string out = "\"";
    for (char c : s) {
        if (c == '"') out += "\"\"";
        else out += c;
    }
    out += "\"";
    return out;
}

ReportService::ReportService(DatabaseConnection<std::string>& db) : db_(db) {}

void ReportService::exportAuditReportCSV(const std::string& filepath) {
    auto rows = db_.executeQuery(
        "SELECT "
        "  o.order_id, "
        "  u.name AS user_name, "
        "  o.status, "
        "  o.total_price, "
        "  o.order_date, "
        "  COALESCE(h.old_status,''), "
        "  COALESCE(h.new_status,''), "
        "  COALESCE(h.changed_at::text,''), "
        "  COALESCE(au.operation,''), "
        "  COALESCE(au.details,''), "
        "  COALESCE(au.performed_at::text,'') "
        "FROM orders o "
        "JOIN users u ON u.user_id = o.user_id "
        "LEFT JOIN order_status_history h ON h.order_id = o.order_id "
        "LEFT JOIN audit_log au ON au.entity_type='order' AND au.entity_id=o.order_id "
        "ORDER BY o.order_id DESC, h.changed_at DESC, au.performed_at DESC;"
    );

    // ✅ auto-create folder (reports/)
    std::filesystem::path outPath(filepath);
    if (outPath.has_parent_path()) {
        std::filesystem::create_directories(outPath.parent_path());
    }

    std::ofstream f(filepath);
    if (!f.is_open()) {
        throw std::runtime_error("Cannot open file for writing: " + filepath);
    }

    f << "order_id,user_name,status,total_price,order_date,old_status,new_status,changed_at,operation,details,performed_at\n";

    for (auto& r : rows) {
        for (size_t i = 0; i < r.size(); ++i) {
            if (i) f << ",";
            f << csvEscape(r[i]);
        }
        f << "\n";
    }

    f.close();
    std::cout << "Report exported ✅ -> " << filepath << "\n";
}
