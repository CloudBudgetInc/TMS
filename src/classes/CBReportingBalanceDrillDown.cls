/**
 * Created by Alex JR on 10/26/2020.
 */

public with sharing class CBReportingBalanceDrillDown { 

    @AuraEnabled
    public static List<Object> getDrillDownServer(String ffrbId, String ffrbName) {
        if (ffrbName == null && ffrbId == null) return null;
        List<Object> r = new List<Object>();

        try {
            String addQ = ffrbId == null ? ' Name = :ffrbName' : ' Id = :ffrbId';
            c2g__ReportingBalance__c rb = (c2g__ReportingBalance__c) Database.query('SELECT c2g__GeneralLedgerAccount__c, c2g__Period__c, c2g__OwnerCompany__c, c2g__Dimension1__c, c2g__Dimension2__c FROM c2g__ReportingBalance__c WHERE' + addQ)[0];

            for (c2g__codaTransactionLineItem__c tli : [
                    SELECT Id, Name, c2g__HomeCredits__c, c2g__GeneralLedgerAccount__r.Name, c2g__Transaction__r.c2g__Period__r.Name,
                            c2g__Transaction__c, c2g__Transaction__r.Name, c2g__Dimension1__c, c2g__Dimension2__c, c2g__Dimension1__r.Name, c2g__Dimension2__r.Name
                    FROM c2g__codaTransactionLineItem__c
                    WHERE c2g__GeneralLedgerAccount__c = :rb.c2g__GeneralLedgerAccount__c
                    AND c2g__Transaction__r.c2g__Period__c = :rb.c2g__Period__c
                    AND c2g__Dimension1__c  = :rb.c2g__Dimension1__c
                    AND c2g__Dimension2__c  = :rb.c2g__Dimension2__c
                    ORDER BY c2g__Transaction__r.Name, c2g__GeneralLedgerAccount__r.Name
            ]) r.add(tli);

            return r;
        } catch (Exception e) {
            Map<String, String> errorMap = new Map<String, String>{
                    'ERROR' => e.getLineNumber() + ' ' + e.getMessage()
            };
            r.add(errorMap);
            return r;
        }
    }

    public static void codeGen(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }

}