/**
 * Created by Alex JR on 8/31/2020.
 * The controller of the report for mapping refine
 */

public with sharing class CBMappingReport {

    private static final String generalDimension = 'Unspecified';
    private static final String lvl1 = 'Level 1';
    private static final String lvl2 = 'Level 2';
    private static final String lvl3 = 'Level 3';
    private static final Integer abbrLen = 30;

    /**
     *
     *
     * @param yearNumber  2020 || 2025
     * @param type  DOUBLED || UNMAPPED
     *
     * @return
     */
    @AuraEnabled
    public static Map<String, Object> getReportDataServer(String yearNumber, String type) {
        Map<String, Object> r = new Map<String, Object>();
        r.put('yearsSO', CBService.getYearsSO());
        if (type == 'DOUBLED') r.put('doublingLines', getDoubledCombinations());
        if (type == 'UNMAPPED') r.put('unmappedLines', getUnmappedCombinations(yearNumber));
        return r;
    }


    /////// DOUBLED MAPPING ///////
    private static List<ReportWrapper> getDoubledCombinations() {
        List<ReportWrapper> r = new List<CBMappingReport.ReportWrapper>();
        Map<String, Budget_Reporting_Department_Line__c> keys = new Map<String, Budget_Reporting_Department_Line__c>();
        Map<String, String> doubles = new Map<String, String>(); // source line Id, doubled line Id
        Map<String, Budget_Reporting_Department_Line__c> allLinesMap = new Map<String, Budget_Reporting_Department_Line__c>();
        for (Budget_Reporting_Department_Line__c line : CBService.getBudgetReportingLines()) {
            String key = (String) line.Budget_Reporting_Department__r.Reporting_Level__c + line.Dimension_1__c + line.Dimension_2__c;
            if (keys.keySet().contains(key)) doubles.put(line.Id, (keys.get(key)).Id);
            keys.put(key, line);
            allLinesMap.put(line.Id, line);
        }
        for (String lineId : doubles.keySet()) r.add(getReportWrapper(allLinesMap.get(lineId), allLinesMap.get(doubles.get(lineId))));
        return r;
    }
    @TestVisible
    private static ReportWrapper getReportWrapper(Budget_Reporting_Department_Line__c line, Budget_Reporting_Department_Line__c line2) {
        ReportWrapper r = new ReportWrapper();
        r.dimension1Name = line.Dimension_1__c == null ? generalDimension : line.Dimension_1__r.Name.abbreviate(abbrLen);
        r.dimension2Name = line.Dimension_2__c == null ? generalDimension : line.Dimension_2__r.Name.abbreviate(abbrLen);
        r.budgetReportingDepartmentId = line.Budget_Reporting_Department__c;
        r.budgetReportingDepartmentName = line.Budget_Reporting_Department__r.Name.abbreviate(abbrLen);
        r.budgetReportingDepartmentLevel = line.Budget_Reporting_Department__r.Reporting_Level__c.replace('Level ', '');
        r.budgetReportingDepartmentId2 = line2.Budget_Reporting_Department__c;
        r.budgetReportingDepartmentName2 = line2.Budget_Reporting_Department__r.Name.abbreviate(abbrLen);
        r.budgetReportingDepartmentLineId = line.Id;
        r.budgetReportingDepartmentLineId2 = line2.Id;
        r.budgetReportingDepartmentLineName = line.Name.replace('BDL-', '');
        r.budgetReportingDepartmentLineName2 = line2.Name.replace('BDL-', '');
        return r;
    }
    /////// DOUBLED MAPPING ///////

    /////// UNMAPPED        ///////
    @TestVisible
    private static List<ReportWrapper> getUnmappedCombinations(String yearNumber) {
        List<ReportWrapper> r = new List<CBMappingReport.ReportWrapper>();
        String key;
        Set<String> keySet1 = new Set<String>();
        Set<String> keySet2 = new Set<String>();
        Set<String> keySet3 = new Set<String>();
        for (Budget_Reporting_Department_Line__c line : CBService.getBudgetReportingLines()) {
            key = (String) line.Budget_Reporting_Department__r.Reporting_Level__c + line.Dimension_1__c + line.Dimension_2__c;
            if (line.Budget_Reporting_Department__r.Reporting_Level__c == lvl1) {
                keySet1.add(key);
            } else if (line.Budget_Reporting_Department__r.Reporting_Level__c == lvl2) {
                keySet2.add(key);
            } else {
                keySet3.add(key);
            }
        }

        Set<String> uniqueKeys = new Set<String>();
        for (List<c2g__ReportingBalance__c> rbLoop : [
                SELECT c2g__Dimension1__c, c2g__Dimension2__c, c2g__Dimension1__r.Name, c2g__Dimension2__r.Name, Name, Id
                FROM c2g__ReportingBalance__c
                WHERE c2g__YearNumber__c = :Integer.valueOf(yearNumber) AND c2g__GeneralLedgerAccount__r.c2g__Type__c = 'Profit and loss'
                AND c2g__DualValue__c != 0 AND c2g__Type__c = 'Actual'
                ORDER BY c2g__Dimension1__r.Name, c2g__Dimension2__r.Name
                LIMIT 50000
        ]) {
            for (c2g__ReportingBalance__c rb : rbLoop) {
                key = lvl1 + rb.c2g__Dimension1__c + rb.c2g__Dimension2__c;
                if (!keySet1.contains(key) && !uniqueKeys.contains(key)) {
                    r.add(getUnmappedWrapper(rb, lvl1));
                    uniqueKeys.add(key);
                }

                key = lvl2 + rb.c2g__Dimension1__c + rb.c2g__Dimension2__c;
                if (!keySet2.contains(key) && !uniqueKeys.contains(key)) {
                    r.add(getUnmappedWrapper(rb, lvl2));
                    uniqueKeys.add(key);
                }

                key = lvl3 + rb.c2g__Dimension1__c + rb.c2g__Dimension2__c;
                if (!keySet3.contains(key) && !uniqueKeys.contains(key)) {
                    r.add(getUnmappedWrapper(rb, lvl3));
                    uniqueKeys.add(key);
                }
            }
        }
        //budgetReportingDepartmentLevel
        List<ReportWrapper> r1 = new List<CBMappingReport.ReportWrapper>();
        List<ReportWrapper> r2 = new List<CBMappingReport.ReportWrapper>();
        List<ReportWrapper> r3 = new List<CBMappingReport.ReportWrapper>();
        for (ReportWrapper rw : r) if (rw.budgetReportingDepartmentLevel == '1') r1.add(rw); else if (rw.budgetReportingDepartmentLevel == '2')r2.add(rw); else if (rw.budgetReportingDepartmentLevel == '3')r3.add(rw);

        r = new List<CBMappingReport.ReportWrapper>();
        r.addAll(r1);
        r.addAll(r2);
        r.addAll(r3);

        return r;
    }
    @TestVisible
    private static ReportWrapper getUnmappedWrapper(c2g__ReportingBalance__c rb, String lvl) {
        ReportWrapper r = new ReportWrapper();
        r.rbExampleId = rb.Id;
        r.rbExampleName = rb.Name;
        r.budgetReportingDepartmentLevel = lvl.replace('Level ', '');
        r.dimension1Name = rb.c2g__Dimension1__c == null ? generalDimension : rb.c2g__Dimension1__r.Name;
        r.dimension2Name = rb.c2g__Dimension2__c == null ? generalDimension : rb.c2g__Dimension2__r.Name;
        return r;
    }
    /////// UNMAPPED        ///////


    @AuraEnabled
    public static List<Object> searchReportingDepartmentsServer(String dim1Name, String dim2Name) {
        List<Object> r = new List<Object>();
        String q = 'SELECT Id, Name, Budget_Reporting_Department__r.Name, Reporting_Department_Level__c, Dimension_1__r.Name, Dimension_2__r.Name ' +
                ' FROM Budget_Reporting_Department_Line__c ' +
                ' WHERE Dimension_1__r.Name LIKE \'%' + dim1Name + '%\'  ' +
                (dim2Name == null || dim2Name == '' ? '' : ' AND Dimension_2__r.Name LIKE \'%' + dim2Name + '%\'  ') +
                ' ORDER BY Reporting_Department_Level__c';
        for (Budget_Reporting_Department_Line__c brdl : Database.query(q)) r.add(brdl);
        return r;
    }

    /////// CLASSES         ///////
    public class ReportWrapper {
        @AuraEnabled public String budgetReportingDepartmentId { get; set; }
        @AuraEnabled public String budgetReportingDepartmentName { get; set; }
        @AuraEnabled public String budgetReportingDepartmentLevel { get; set; }
        @AuraEnabled public String budgetReportingDepartmentId2 { get; set; }
        @AuraEnabled public String budgetReportingDepartmentName2 { get; set; }
        @AuraEnabled public String budgetReportingDepartmentLevel2 { get; set; }
        @AuraEnabled public String dimension1Name { get; set; }
        @AuraEnabled public String dimension2Name { get; set; }
        @AuraEnabled public String budgetReportingDepartmentLineId { get; set; }
        @AuraEnabled public String budgetReportingDepartmentLineName { get; set; }
        @AuraEnabled public String budgetReportingDepartmentLineId2 { get; set; }
        @AuraEnabled public String budgetReportingDepartmentLineName2 { get; set; }
        @AuraEnabled public String rbExampleId { get; set; }
        @AuraEnabled public String rbExampleName { get; set; }
        public override String toString() {
            return this.budgetReportingDepartmentLevel + ' Dim1: ' + dimension1Name + ' Dim2: ' + dimension2Name;
        }
    }
    /////// CLASSES         ///////
}