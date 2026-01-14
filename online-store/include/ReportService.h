#pragma once
#include <string>
#include "DatabaseConnection.h"

class ReportService {
public:
    explicit ReportService(DatabaseConnection<std::string>& db);

    // export CSV report
    void exportAuditReportCSV(const std::string& filepath);

private:
    DatabaseConnection<std::string>& db_;
};
