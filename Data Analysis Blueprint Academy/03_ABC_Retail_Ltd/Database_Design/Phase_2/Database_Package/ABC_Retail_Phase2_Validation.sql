/*
ABC Retail Ltd Phase 2 Validation and Casebook Readiness Tests
Document Code: DABA-ABC-DB-005
*/
SET NOCOUNT ON;
USE ABC_Retail_Phase1;
GO

DECLARE @RequiredObjects TABLE(ObjectName SYSNAME,ObjectType CHAR(2));
INSERT INTO @RequiredObjects VALUES
('logistics.Routes','U'),('logistics.Vehicles','U'),('logistics.Drivers','U'),
('logistics.Deliveries','U'),('logistics.DeliveryItems','U'),('logistics.VehicleMaintenance','U'),
('inventory.StockCounts','U'),('inventory.StockCountItems','U'),
('procurement.GoodsReceipts','U'),('procurement.GoodsReceiptItems','U'),('procurement.SupplierPerformance','U'),
('marketing.MarketingLeads','U'),('marketing.MarketingExpenses','U'),
('crm.LoyaltyTransactions','U'),('service.CustomerInteractions','U'),
('it.Systems','U'),('it.ITAssets','U'),('it.SystemUsers','U'),('it.ITSupportTickets','U'),
('security.SecurityControls','U'),('security.Vulnerabilities','U'),('security.SecurityAlerts','U'),
('security.SecurityIncidents','U'),('risk.RiskRegister','U'),('audit.Audits','U'),
('audit.AuditFindings','U'),('audit.CorrectiveActions','U'),
('bi.KPIDefinitions','U'),('bi.KPIValidationLog','U'),('bi.KPIPublications','U'),('bi.KPIPublicationItems','U');

SELECT ObjectName,CASE WHEN OBJECT_ID(ObjectName,ObjectType) IS NOT NULL THEN 'PASS' ELSE 'FAIL' END TestResult
FROM @RequiredObjects ORDER BY ObjectName;
GO

SELECT 'Deliveries' TestArea,COUNT(*) RecordCount,CASE WHEN COUNT(*)>=100 THEN 'PASS' ELSE 'FAIL' END TestResult FROM logistics.Deliveries
UNION ALL SELECT 'IT Support Tickets',COUNT(*),CASE WHEN COUNT(*)>=150 THEN 'PASS' ELSE 'FAIL' END FROM it.ITSupportTickets
UNION ALL SELECT 'Security Alerts',COUNT(*),CASE WHEN COUNT(*)>=200 THEN 'PASS' ELSE 'FAIL' END FROM security.SecurityAlerts
UNION ALL SELECT 'Security Incidents',COUNT(*),CASE WHEN COUNT(*)>=30 THEN 'PASS' ELSE 'FAIL' END FROM security.SecurityIncidents
UNION ALL SELECT 'Audit Findings',COUNT(*),CASE WHEN COUNT(*)>=30 THEN 'PASS' ELSE 'FAIL' END FROM audit.AuditFindings
UNION ALL SELECT 'KPI Definitions',COUNT(*),CASE WHEN COUNT(*)>=22 THEN 'PASS' ELSE 'FAIL' END FROM bi.KPIDefinitions;
GO

/* Delivery performance */
SELECT b.BranchName,COUNT(*) DeliveredOrders,
 SUM(CASE WHEN d.ActualDeliveryDate<=d.ExpectedDeliveryDate THEN 1 ELSE 0 END) OnTimeOrders,
 CAST(100.0*SUM(CASE WHEN d.ActualDeliveryDate<=d.ExpectedDeliveryDate THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0) AS DECIMAL(6,2)) OnTimeDeliveryPct,
 AVG(CASE WHEN d.ActualDeliveryDate IS NULL THEN NULL ELSE CAST(DATEDIFF(HOUR,d.ExpectedDeliveryDate,d.ActualDeliveryDate) AS DECIMAL(10,2)) END) AverageDelayHours
FROM logistics.Deliveries d JOIN core.Branches b ON b.BranchID=d.BranchID
WHERE d.DeliveryStatus='Delivered' GROUP BY b.BranchName ORDER BY OnTimeDeliveryPct;
GO

/* Fleet maintenance */
SELECT v.VehicleCode,v.RegistrationNumber,COUNT(m.MaintenanceID) MaintenanceEvents,
 SUM(m.MaintenanceCost) TotalMaintenanceCost,SUM(m.DowntimeHours) TotalDowntimeHours
FROM logistics.Vehicles v LEFT JOIN logistics.VehicleMaintenance m ON m.VehicleID=v.VehicleID
GROUP BY v.VehicleCode,v.RegistrationNumber ORDER BY TotalMaintenanceCost DESC;
GO

/* Stock variance */
SELECT w.WarehouseName,p.ProductCode,p.ProductName,SUM(i.VarianceQuantity) NetVarianceQuantity,
 SUM(i.VarianceValue) NetVarianceValue
FROM inventory.StockCountItems i
JOIN inventory.StockCounts c ON c.StockCountID=i.StockCountID
JOIN inventory.Warehouses w ON w.WarehouseID=c.WarehouseID
JOIN product.Products p ON p.ProductID=i.ProductID
GROUP BY w.WarehouseName,p.ProductCode,p.ProductName
HAVING SUM(ABS(i.VarianceQuantity))>0 ORDER BY ABS(SUM(i.VarianceValue)) DESC;
GO

/* Supplier performance */
SELECT s.SupplierCode,s.SupplierName,p.OrdersPlaced,p.OrdersDeliveredOnTime,
 CAST(100.0*p.OrdersDeliveredOnTime/NULLIF(p.OrdersPlaced,0) AS DECIMAL(6,2)) OnTimeDeliveryPct,
 p.QualityScore,p.ServiceScore,p.PriceScore,p.OverallScore,p.PerformanceStatus
FROM procurement.SupplierPerformance p JOIN procurement.Suppliers s ON s.SupplierID=p.SupplierID
ORDER BY p.OverallScore DESC;
GO

/* Marketing */
SELECT c.CampaignCode,c.CampaignName,COUNT(l.LeadID) TotalLeads,
 SUM(CASE WHEN l.LeadStatus='Converted' THEN 1 ELSE 0 END) ConvertedLeads,
 CAST(100.0*SUM(CASE WHEN l.LeadStatus='Converted' THEN 1 ELSE 0 END)/NULLIF(COUNT(l.LeadID),0) AS DECIMAL(6,2)) ConversionRatePct,
 ISNULL(e.CampaignSpend,0) CampaignSpend
FROM marketing.MarketingCampaigns c
LEFT JOIN marketing.MarketingLeads l ON l.CampaignID=c.CampaignID
LEFT JOIN(SELECT CampaignID,SUM(Amount+TaxAmount) CampaignSpend FROM marketing.MarketingExpenses GROUP BY CampaignID)e ON e.CampaignID=c.CampaignID
GROUP BY c.CampaignCode,c.CampaignName,e.CampaignSpend ORDER BY ConversionRatePct DESC;
GO

/* IT support */
SELECT b.BranchName,t.TicketCategory,t.Priority,COUNT(*) TicketCount,
 AVG(CASE WHEN t.ResolvedAt IS NULL THEN NULL ELSE CAST(DATEDIFF(MINUTE,t.CreatedAt,t.ResolvedAt)/60.0 AS DECIMAL(10,2)) END) AverageResolutionHours,
 SUM(CASE WHEN t.TicketStatus IN('Open','Assigned','InProgress','PendingUser') THEN 1 ELSE 0 END) OpenTickets
FROM it.ITSupportTickets t JOIN core.Branches b ON b.BranchID=t.BranchID
GROUP BY b.BranchName,t.TicketCategory,t.Priority ORDER BY OpenTickets DESC,TicketCount DESC;
GO

/* Security */
SELECT Severity,IncidentStatus,COUNT(*) IncidentCount,
 AVG(CASE WHEN ResolvedDate IS NULL THEN NULL ELSE CAST(DATEDIFF(MINUTE,DetectedDate,ResolvedDate)/60.0 AS DECIMAL(10,2)) END) AverageResolutionHours,
 SUM(EstimatedLoss) EstimatedLoss
FROM security.SecurityIncidents GROUP BY Severity,IncidentStatus
ORDER BY CASE Severity WHEN 'Critical' THEN 1 WHEN 'High' THEN 2 WHEN 'Medium' THEN 3 ELSE 4 END;
GO

/* Risk and audit */
SELECT d.DepartmentName,COUNT(DISTINCT r.RiskID) Risks,
 SUM(CASE WHEN r.InherentRiskScore>=15 THEN 1 ELSE 0 END) HighInherentRisks,
 COUNT(DISTINCT f.FindingID) AuditFindings,
 SUM(CASE WHEN f.FindingStatus<>'Closed' AND f.TargetDate<CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END) OverdueFindings
FROM core.Departments d
LEFT JOIN risk.RiskRegister r ON r.DepartmentID=d.DepartmentID
LEFT JOIN audit.AuditFindings f ON f.DepartmentID=d.DepartmentID
GROUP BY d.DepartmentName ORDER BY OverdueFindings DESC,HighInherentRisks DESC;
GO

/* KPI assurance */
SELECT d.KPICode,d.KPIName,COUNT(v.KPIValidationID) Validations,
 SUM(CASE WHEN v.ValidationStatus IN('Valid','ValidWithException','Corrected') THEN 1 ELSE 0 END) AcceptedValidations,
 CAST(100.0*SUM(CASE WHEN v.ValidationStatus IN('Valid','ValidWithException','Corrected') THEN 1 ELSE 0 END)/NULLIF(COUNT(v.KPIValidationID),0) AS DECIMAL(6,2)) ValidationRatePct
FROM bi.KPIDefinitions d LEFT JOIN bi.KPIValidationLog v ON v.KPIDefinitionID=d.KPIDefinitionID
GROUP BY d.KPICode,d.KPIName ORDER BY d.KPICode;
GO
PRINT 'Phase 2 validation queries completed.';
GO
