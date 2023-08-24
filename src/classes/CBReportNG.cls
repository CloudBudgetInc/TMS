/**
 * Created by Alex JR on 10/04/20.
 */

public with sharing class CBReportNG {

    /**
     * @param reportId
     *
     * @return Report Object
     */
    @AuraEnabled
    public static cb4__CBReport__c getReportServer(Id reportId) {
        String q = 'SELECT cb4__CBalanceRule1__r.cb4__isLocked__c, ' + cb4.CBUtils.getAllSObjectFields('cb4__CBReport__c', null) + ' WHERE Id=\'' + reportId + '\' ORDER BY Name LIMIT 1';
        List<cb4__CBReport__c> t = Database.query(q);
        return t[0];
    }

    /**
     * @param reportId
     *
     * @return a list of Report Columns if reportId = null
     */
    @AuraEnabled
    public static List<cb4__CBReportColumn__c> getReportColumnsServer(Id reportId) {
        String q = 'SELECT cb4__CBalanceAmountField__c,cb4__CBRule1__c,cb4__Column__c,cb4__DisplayGroup__c,Name,cb4__OrderNumber__c,' +
                'cb4__ReportColumn1__c,cb4__ReportColumn2__c,cb4__ReportColumn3__c,cb4__ReportColumn4__c,cb4__Status__c,' +
                'cb4__Relation1__c,cb4__Relation2__c,cb4__Relation3__c,cb4__Relation4__c,cb4__Type__c,cb4__Color__c ' +
                'FROM cb4__CBReportColumn__c ' ;
        String w = ' WHERE cb4__Report__c = \'' + reportId + '\' ' +
                ' ORDER BY cb4__OrderNumber__c, Name';
        return Database.query(q + w);
    }

    @AuraEnabled
    public static List<String> getReportHeadersServer(Id reportId) {
        List<String> r = new List<String>();
        Integer counter = 0;
        List<String> colNames = new List<String>();
        Id balRuleId;
        for (cb4__CBReportColumn__c col : getReportColumnsServer(reportId)) {
            colNames.add(col.Name);
            if (col.cb4__CBRule1__c != null) balRuleId = col.cb4__CBRule1__c;
        }
        if (balRuleId == null) return r;
        cb4__CBalanceRule__c br = [SELECT cb4__Lvl1Label__c,cb4__Lvl2Label__c,cb4__Lvl3Label__c,cb4__Lvl4Label__c,cb4__Lvl5Label__c,cb4__Lvl6Label__c,cb4__Lvl7Label__c FROM cb4__CBalanceRule__c WHERE Id = :balRuleId];
        if (br.cb4__Lvl1Label__c != null) counter = helpAddHeader(r, counter, br.cb4__Lvl1Label__c);
        if (br.cb4__Lvl2Label__c != null) counter = helpAddHeader(r, counter, br.cb4__Lvl2Label__c);
        if (br.cb4__Lvl3Label__c != null) counter = helpAddHeader(r, counter, br.cb4__Lvl3Label__c);
        if (br.cb4__Lvl4Label__c != null) counter = helpAddHeader(r, counter, br.cb4__Lvl4Label__c);
        if (br.cb4__Lvl5Label__c != null) counter = helpAddHeader(r, counter, br.cb4__Lvl5Label__c);
        if (br.cb4__Lvl6Label__c != null) counter = helpAddHeader(r, counter, br.cb4__Lvl6Label__c);
        if (br.cb4__Lvl7Label__c != null) counter = helpAddHeader(r, counter, br.cb4__Lvl7Label__c);
        r.addAll(colNames);
        r.add(String.valueOf(counter));
        return r;
    }

    @AuraEnabled
    public static List<cb4__CBalance__c> getCBalancesServer(Id reportId) {
        Set<Id> balIds = new Set<Id>(); //list of CBalance Rules
        Set<Id> periodIds = new Set<Id>(); //list of Periods
        for (cb4__CBReportColumn__c col : getReportColumnsServer(reportId)) {
            if (col.cb4__CBRule1__c != null) balIds.add(col.cb4__CBRule1__c); // restriction by CBalance Rule
            if (col.cb4__Column__c != null) periodIds.add(col.cb4__Column__c); // restriction by Periods
        }

        cb4__CBReport__c cReport = [SELECT Id, cb4__CBalanceFilter__c FROM cb4__CBReport__c WHERE Id = :reportId];

        List<cb4__CBalance__c> r = Database.query('SELECT cb4__Amount1__c, cb4__Amount2__c, cb4__Amount3__c, cb4__Amount4__c, cb4__Amount5__c, cb4__Amount2_1__c, cb4__Amount1YTD__c, cb4__Amount2YTD__c, cb4__Amount3YTD__c, cb4__Amount4YTD__c, cb4__Amount5YTD__c, cb4__Amount2_1YTD__c, cb4__Column__c, cb4__Lvl1Name__c, cb4__Lvl2Name__c, cb4__Lvl3Name__c, cb4__Lvl4Name__c, cb4__Lvl5Name__c, cb4__Lvl6Name__c, cb4__Lvl7Name__c, cb4__Key__c FROM cb4__CBalance__c WHERE ' + (String.isBlank(cReport.cb4__CBalanceFilter__c) ? '' : ('(' + cReport.cb4__CBalanceFilter__c + ') AND')) + ' cb4__CBalanceRule__c IN:balIds AND cb4__Column__c IN:periodIds AND (cb4__Amount1__c != 0 OR cb4__Amount2__c != 0 OR cb4__Amount3__c != 0 OR cb4__Amount4__c != 0 OR cb4__Amount5__c != 0 OR cb4__Amount1YTD__c != 0 OR cb4__Amount2YTD__c != 0 OR cb4__Amount3YTD__c != 0 OR cb4__Amount4YTD__c != 0 OR cb4__Amount5YTD__c != 0) ORDER BY cb4__Lvl1__r.cb4__OrderNumber__c, cb4__Lvl1Name__c, cb4__Lvl2__r.cb4__OrderNumber__c, cb4__Lvl2Name__c, cb4__Lvl3__r.cb4__OrderNumber__c, cb4__Lvl3Name__c, cb4__Lvl4__r.cb4__OrderNumber__c, cb4__Lvl4Name__c, cb4__Lvl5__r.cb4__OrderNumber__c, cb4__Lvl5Name__c, cb4__Lvl6__r.cb4__OrderNumber__c, cb4__Lvl6Name__c, cb4__Lvl7__r.cb4__OrderNumber__c, cb4__Lvl7Name__c LIMIT 50000 ');


        ////////////////// EXPERIMENT  ///////////////
        //r = CBCurrency.convertAmountsToUserCurrency(r);
        ////////////////// EXPERIMENT  ///////////////

        return r;
    }

    /**
     * @param reportId
     *
     * @return
     */
    @AuraEnabled
    public static List<String> getDisplayGroupsServer(Id reportId) {
        Set <String> r = new Set<String>();
        for (cb4__CBReportColumn__c col : [SELECT cb4__DisplayGroup__c FROM cb4__CBReportColumn__c WHERE cb4__Report__c = :reportId]) {
            if (col.cb4__DisplayGroup__c == null) continue;
            List<String> t = col.cb4__DisplayGroup__c.split(',');
            for (String s : t) if (s != null) r.add(s.trim()); else continue;
        }
        List<String> e = new List<String>(r);
        e.sort();
        return e;
    }

    /**
     * @param reportId current report Id
     *
     * @return Background information for the report warning message
     */
    @AuraEnabled
    public static List<String> getLastUpdateMessageServer(Id reportId) {
        List<String> r = new List<String>();
        cb4__CBLog__c trk = [SELECT Id, CreatedDate FROM cb4__CBLog__c WHERE cb4__Type__c = 'TRACKING' LIMIT 1];
        if (trk == null) return r; // no warning message needed
        r.add(String.valueOf(trk.CreatedDate));

        if (reportId != null) {
            List<cb4__CBReportColumn__c> rows = [SELECT cb4__CBRule1__c FROM cb4__CBReportColumn__c WHERE cb4__Report__c = :reportId ORDER BY cb4__OrderNumber__c DESC LIMIT 1];
            if (rows.size() > 0) {
                List<cb4__CBalance__c> bas = [SELECT CreatedDate FROM cb4__CBalance__c WHERE cb4__CBalanceRule__c = :rows[0].cb4__CBRule1__c ORDER BY CreatedDate DESC LIMIT 1];
                if (bas.size() > 0) r.add(String.valueOf(bas[0].CreatedDate));
            }
        }
        return r;
    }

/////// PRIVATE METHODS ///////
    @TestVisible
    private static Integer helpAddHeader(List<String> r, Integer i, String label) {
        r.add(label);
        return ++i;
    }
/////// PRIVATE METHODS ///////

}