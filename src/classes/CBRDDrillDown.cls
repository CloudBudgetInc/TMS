/**
 * Created by Alex JR on 9/25/2020.
 */

public with sharing class CBRDDrillDown {

    /**
     *
     * @param CBalanceKey unique key for CBalance__c (id of each group)
     * @param reportId report Id
     * @param columnId period Id (month)
     *
     *
     * Cbalance key is:
     * CB2BRD,                                      = CB Reporting Department
     * ea.cb4__Tag2__r.cb4__Tag1__r.cb4__Tag1__c,   = Entry Account Type
     * ea.cb4__Tag2__r.cb4__Tag1__c,                = Entry Account SubType
     * ea.cb4__Tag2__c,                             = Entry Account
     * ea.cb4__Tag1__r.cb4__Tag9__c                 = BDG
     *
     * @return
     */
    @AuraEnabled
    public static Map<String, Object> getDrillDown(String CBalanceKey, Id reportId, Id columnId) {
        Map<String, Object> r = new Map<String, Object>();

        String CBalRuleId = [SELECT cb4__CBalanceRule1__c FROM cb4__CBReport__c WHERE Id = :reportId].cb4__CBalanceRule1__c;

        String accId = CBalanceKey.substring(54, 72);

        System.debug('KEY=' + CBalanceKey);
        System.debug('accId=' + accId);

        try {
            String accountName = 'N/A';
            List<cb4__CBalance__c> bals = [SELECT cb4__DrillDown__c, cb4__Column__r.Name FROM cb4__CBalance__c WHERE cb4__Key__c = :CBalanceKey AND cb4__Column__c = :columnId AND cb4__CBalanceRule__c = :CBalRuleId LIMIT 1];
            if (bals.size() == 0) {
                r.put('warning', 'No balances for this period');
                return r;
            }
            if (bals[0].cb4__DrillDown__c == null || bals[0].cb4__DrillDown__c == '') {
                r.put('warning', 'No drill down references were founded');
                return r;
            }
            cb4__CBalance__c balance = bals[0];
            Integer numberOfEntries = bals[0].cb4__DrillDown__c.split(',').size();
            String entriesSetString = getEntryIdSet([SELECT cb4__DrillDown__c FROM cb4__CBalance__c WHERE cb4__Key__c = :CBalanceKey AND cb4__CBalanceRule__c = :CBalRuleId LIMIT 10000]);
            String previousPeriodIds = getPreviousPeriodIds(columnId);
            Map<String, String> ddMap = getEntryDrillDown(entriesSetString);

            String q = 'SELECT SUM(cb4__Decimal1__c) amount,' +
                    'cb4__Tag1__c entryId,' +
                    'MAX(cb4__Tag1__r.cb4__TagLabel__c) entryName,' +
                    'MAX(cb4__Tag2__r.cb4__TagLabel__c) accName,' +
                    'cb4__Tag1__r.cb4__Tag4__r.Name accType,' +
                    'MAX(cb4__Tag1__r.cb4__ExtId__c) extId' +
                    ' FROM cb4__CBTag__c ' +
                    ' WHERE ' +
                    ' cb4__Tag3__c IN ' + previousPeriodIds + ' ' + // filter by period
                    ' AND cb4__Tag2__c = \'' + accId + '\' ' + // filter by account like 'AND Tag2__c = xxxxx ' if an entry contain more than one account in its lines
                    ' AND cb4__DimensionName__c = \'Entry Amount\' ' +
                    ' AND cb4__Text1__c = \'main\' ' +
                    ' AND cb4__Tag1__r.cb4__Tag8Name__c = \'Base\' ' +
                    ' AND cb4__Tag1__c IN ' + entriesSetString + // a list of ids of drilled entries
                    ' GROUP BY cb4__Tag1__c, cb4__Tag1__r.cb4__Tag4__r.Name ' ;

            Map<String, Map<String, cb4__CBTag__c>> sectionMap = new Map<String, Map<String, cb4__CBTag__c>>(); // key = entry type (plan || actual) key = entry Id
            List<AggregateResult> entriesAggr = Database.query(q);

            for (AggregateResult t : entriesAggr) {
                Map<String, cb4__CBTag__c> entryMap = sectionMap.get((String) t.get('accType')); // key = Entry Type (plan || actual)
                if (entryMap == null) entryMap = new Map<String, cb4__CBTag__c>();
                cb4__CBTag__c res = entryMap.get((String) t.get('entryId')); // t.Tag1__c = Entry Id
                if (res == null) {
                    String CBRBId = ddMap.get((String) t.get('entryId'));
                    res = new cb4__CBTag__c(Id = (String) t.get('entryId'), Name = (String) t.get('entryName'),
                            cb4__Decimal1__c = 0, cb4__ExtId__c = CBRBId, cb4__Text5__c = ddMap.get(CBRBId));
                }
                res.cb4__Decimal1__c += (Decimal) t.get('amount');
                entryMap.put((String) t.get('entryId'), res);
                sectionMap.put((String) t.get('accType'), entryMap);
                accountName = (String) t.get('accName');
            }

            r.put('account', accountName);
            r.put('period', balance.cb4__Column__r.Name + ' YTD');
            Decimal totalAmount;
            List<Object> sections = new List<Object>();
            for (String key : sectionMap.keySet()) {
                totalAmount = 0;
                List<cb4__CBTag__c> rows = sectionMap.get(key).values();
                for (cb4__CBTag__c t : rows) totalAmount += t.cb4__Decimal1__c;
                rows.add(new cb4__CBTag__c(Name = 'Total', cb4__Decimal1__c = totalAmount, cb4__Text1__c = 'total')); // each section plan and actual have own total
                Map<String, Object> s = new Map<String, Object>();
                s.put('name', key);
                s.put('rows', rows);
                sections.add(s);
            }
            r.put('sections', sections);
            return r;
        } catch (Exception e) {
            r.put('warning', e.getMessage() + ' : ' + e.getLineNumber());
            return r;
        }
    }

    private static String getPreviousPeriodIds(String columnId) {
        Set<String> setOfId = new Set<String>();
        cb4__CBTag__c period = [SELECT Id, cb4__Tag1__c, cb4__Start__c FROM cb4__CBTag__c WHERE Id = :columnId];
        for (cb4__CBTag__c t : [
                SELECT Id
                FROM cb4__CBTag__c
                WHERE cb4__DimensionName__c = 'Period' AND cb4__Tag1__c = :period.cb4__Tag1__c AND cb4__Start__c <= :period.cb4__Start__c
        ]) setOfId.add(t.Id);
        return getFormattedINQuery(setOfId);
    }

    private static String getEntryIdSet(List<cb4__CBalance__c> balances) {
        Set<String> setIds = new Set<String>();
        for (cb4__CBalance__c b : balances) if (b.cb4__DrillDown__c != null && b.cb4__DrillDown__c != '')for (String eid : b.cb4__DrillDown__c.split(',')) setIds.add(eid);
        System.debug('DD size = ' + setIds.size());
        return getFormattedINQuery(setIds);
    }

    private static String getFormattedINQuery(Set<String> s) {
        return s.size() > 0 ? '(\'' + String.join(new List<String>(s), '\', \'') + '\') ' : '';
    }

    /**
     * @param eIds list of Entry Ids
     *
     * @return key = CBRB Id  value = FF
     */
    public static Map<String, String> getEntryDrillDown(String eIds) {
        Map<String, String> r = new Map<String, String>();
        if (eIds == null) return r;
        Set<String> CBRBIds = new Set<String>();
        String q = 'SELECT cb4__Tag1__c, cb4__Tag1Name__c, cb4__Tag2__c FROM cb4__CBLink__c' +
                ' WHERE cb4__Type__c = \'Posting Rule\' AND cb4__Tag2__c IN ' + eIds + ' LIMIT 45000';
        for (cb4__CBLink__c l : Database.query(q)) {
            r.put(l.cb4__Tag2__c, l.cb4__Tag1__c);
            CBRBIds.add(l.cb4__Tag1__c);
        }
        for (cb4__CBTag__c t : [SELECT Id, cb4__ExtId__c FROM cb4__CBTag__c WHERE Id IN:CBRBIds]) r.put(t.Id, t.cb4__ExtId__c);
        return r;
    }

    /**
     * Safety tested ✔ 22/11/2019
     * The method returns dimension name by the CBTag Id
     * @param i
     *
     * @return
     */
    /*private static String getTagType(String i) {
        if (i == 'XXXXXXXXXXXXXXXXXX') return '-';
        return [SELECT cb4__DimensionName__c FROM cb4__CBTag__c WHERE id = :i LIMIT 1].cb4__DimensionName__c;
    }*/


}