/**
 * Created by Alex JR on 9/7/2020.
 */

public with sharing class CBTMSIntegration {

    /**
     * The Mustard Seed's  Budget Reporting Departments  to  CB2 Budget Reporting Departments
    */
    public static void syncBudgetDepartments() {
        Id CBBRDDimensionId = [SELECT Id FROM cb4__CBDimension__c WHERE Name = :CBVariable.CBBRDName LIMIT 1][0].Id;
        List<cb4__CBTag__c> CBBRDToInsert = new List<cb4__CBTag__c>();

        Set<String> CBBRDIds = new Set<String>();
        for (cb4__CBTag__c t : [SELECT cb4__ExtId__c FROM cb4__CBTag__c WHERE cb4__Dimension__c = :CBBRDDimensionId LIMIT 50000]) CBBRDIds.add(t.cb4__ExtId__c);

        for (Budget_Reporting_Department__c brd : [SELECT Id, Name, Reporting_Level__c FROM Budget_Reporting_Department__c LIMIT 50000]) {
            if (CBBRDIds.contains(brd.Id)) continue;
            cb4__CBTag__c newCBBRD = new cb4__CBTag__c (cb4__Dimension__c = CBBRDDimensionId, Name = brd.Name, cb4__ExtId__c = brd.Id, cb4__Text1__c = brd.Reporting_Level__c);
            CBBRDToInsert.add(newCBBRD);
        }

        insert CBBRDToInsert;
    }

}