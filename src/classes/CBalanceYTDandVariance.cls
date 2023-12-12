/**
 * Created by Alex JR on 9/9/2020.
 */

public with sharing class CBalanceYTDandVariance implements Database.Batchable<SObject> {

    private String CBalanceRuleId;
    private List<String> brdIds;
    private String currBrdId;

    public CBalanceYTDandVariance(Id CBalanceRuleId) {
        if (CBalanceRuleId == null) Integer error = 1 / 0;
        this.CBalanceRuleId = CBalanceRuleId;
        List<String> brdIdList = new List<String>();
        for(AggregateResult c : [SELECT cb4__Lvl1__c FROM cb4__CBalance__c WHERE cb4__CBalanceRule__c = :CBalanceRuleId GROUP BY cb4__Lvl1__c]){
            brdIdList.add((String) c.get('cb4__Lvl1__c'));
        }
        currBrdId = brdIdList[0];
        brdIdList.remove(0);
        this.brdIds = brdIdList;
    }

    public CBalanceYTDandVariance(Id CBalanceRuleId, List<String> brdIds) {
        if (CBalanceRuleId == null) Integer error = 1 / 0;
        this.CBalanceRuleId = CBalanceRuleId;
        this.currBrdId = brdIds[0];
        brdIds.remove(0);
        this.brdIds = brdIds;
    }


    public Database.QueryLocator start(Database.BatchableContext context) {
        String q = getMainQuery();
        return Database.getQueryLocator(q);
    }
    public void execute(Database.BatchableContext context, List<cb4__CBalance__c> scope) {
        run(scope);
    }
    public void finish(Database.BatchableContext context) {
        if(!brdIds.isEmpty()){
            Id jobYTDId = Database.executeBatch(new CBalanceYTDandVariance(CBalanceRuleId, brdIds), 830); // 830 is 10k/12
        }
    }

    public void run(List<cb4__CBalance__c> scope) {
        insertOmittedCBalances(scope);
        calculate(CBalanceRuleId, null, scope);
    }

    /**
     * @return ALL CBalances from the base
     */
    private List<cb4__CBalance__c> getAllCBalances() {
        return Database.query(getMainQuery());
    }

    /**
     *
     *
     * @param scope 200 cb4__CBalances__c of batch
     */
    public void insertOmittedCBalances(List<cb4__CBalance__c> balances) {
        insert new cb4__CBLog__c (cb4__Type__c = 'OTHER', cb4__Description__c = '----------OMIT FUNC------------');
        Integer total = 0;

        if (balances.size() == null) return;
        List<cb4__CBalance__c> balancesToInsert = new List<cb4__CBalance__c>(); // new em CBalances

        Set<String> alreadyDoneSet = new Set<String>();
        Set<String> keysSet = new Set<String>();
        for (cb4__CBalance__c b : balances) keysSet.add(b.KeyOwner__c);
        for (List<cb4__CBalance__c> blist : [SELECT KeyOwner__c, cb4__Column__c FROM cb4__CBalance__c WHERE cb4__CBalanceRule__c = :CBalanceRuleId AND cb4__Lvl1__c = :currBrdId ORDER BY KeyOwner__c LIMIT 50000]) {
            for (cb4__CBalance__c b : blist) { // LOOP
                total++;
                if (keysSet.contains(b.KeyOwner__c)) {
                    alreadyDoneSet.add(b.cb4__Column__c + b.KeyOwner__c);
                }
            }
        }

        insert new cb4__CBLog__c (cb4__Type__c = 'OTHER', cb4__Description__c = 'TOTAL SIZE OF CBS = ' + total); // LOG

        Map<String, cb4__CBTag__c> periodIds = getPeriodIds(balances[0].cb4__Column__c); // 12 periods

        // key = CBalance KEY    value  =  (  key =  period   value  =  CBalance )
        String pk;
        for (cb4__CBalance__c b : balances) { // each balance from the scope
            for (String periodId : periodIds.keySet()) { // iteration over 12 months
                pk = periodId + b.KeyOwner__c;
                if (alreadyDoneSet.contains(pk)) continue;
                alreadyDoneSet.add(pk);
                balancesToInsert.add(getNewCBalance(b, periodId));
            }
        }
        insert new cb4__CBLog__c (cb4__Type__c = 'OTHER', cb4__Description__c = 'YTD CBalances To Insert size = ' + balancesToInsert.size());
        insert balancesToInsert;
    }

    public void calculate(Id CBalanceRuleId, Map<String, Object> params, List<cb4__CBalance__c> scope) {

        Set<String> balanceKeys = new Set<String>();
        for (cb4__CBalance__c b : scope) balanceKeys.add(b.KeyOwner__c);
        List<cb4__CBalance__c> balances = [
                SELECT cb4__Amount1__c,cb4__Amount2__c,cb4__Amount3__c,cb4__Amount4__c,cb4__Amount5__c,KeyOwner__c,cb4__Column__c,cb4__CBalanceRule__c,
                        cb4__Lvl1__c,cb4__Lvl2__c,cb4__Lvl3__c,cb4__Lvl4__c,cb4__Lvl5__c,cb4__Lvl6__c,cb4__Lvl7__c,cb4__Key__c
                FROM cb4__CBalance__c
                WHERE KeyOwner__c IN:balanceKeys AND cb4__CBalanceRule__c = :CBalanceRuleId AND cb4__Lvl1__c = :currBrdId
                ORDER BY KeyOwner__c, cb4__Column__r.cb4__OrderNumber__c
        ];
        nullifyYTDAmounts(balances);
        Map<String, List<cb4__CBalance__c>> operationalMap = new Map<String, List<cb4__CBalance__c>>(); // String = CBalance key
        cb4__CBalance__c previousBalance;
        for (cb4__CBalance__c b : balances) {
            List<cb4__CBalance__c> CBalanceList = operationalMap.get(b.KeyOwner__c);
            if (CBalanceList == null) CBalanceList = new List<cb4__CBalance__c>();
            previousBalance = CBalanceList.size() == 0 ? null : CBalanceList[CBalanceList.size() - 1];
            addYTDValues(b, previousBalance);
            addVarianceValues(b);
            CBalanceList.add(b);
            operationalMap.put(b.KeyOwner__c, CBalanceList);
        }
        //updatePercentsOfTheSameKeyCBalances(balances);
        upsert balances;
        updateLastUsingDateAndDescription([SELECT Id FROM cb4__CBalanceRule__c WHERE Id = :CBalanceRuleId]);
    }

    /*private static void updatePercentsOfTheSameKeyCBalances(List<cb4__CBalance__c> balances) {
        Map<String, List<cb4__CBalance__c>> sortingMap = new Map<String, List<cb4__CBalance__c>>(); // key = period + balance key
        for (cb4__CBalance__c balance : balances) {
            String key = balance.cb4__Column__c + balance.cb4__Key__c;
            List<cb4__CBalance__c> tmp = sortingMap.get(key);
            if (tmp == null) tmp = new List<cb4__CBalance__c>();
            tmp.add(balance);
            sortingMap.put(key, tmp);
        }

        for (String key : sortingMap.keySet()) {
            List<cb4__CBalance__c> tmp = sortingMap.get(key);
            if (tmp.size() > 1) {
                calculateAveragePercent(tmp);
            } else {
                if (Math.abs(tmp[0].cb4__Amount2YTD__c) >= Math.abs(tmp[0].cb4__Amount1YTD__c)) {
                    tmp[0].cb4__Amount3YTD__c = 0;
                    tmp[0].cb4__Amount4YTD__c = 0;
                }
            }
        }
    }

    *//**
     * cb4__Amount3YTD__c - DIFFERENCE
     * cb4__Amount4YTD__c - PERCENT
     *//*
    private static void calculateAveragePercent(List<cb4__CBalance__c> balances) {
        Decimal amount1 = 0, amount2 = 0;
        for (cb4__CBalance__c balance : balances) {
            amount1 += balance.cb4__Amount1YTD__c;
            amount2 += balance.cb4__Amount2YTD__c;
        }
        Decimal difference = ((amount2 - amount1) / balances.size()).setScale(0);
        Decimal percent = amount1 == 0 ? 0 : (amount2 / amount1 * 100 / balances.size()).setScale(0);
        if (Math.abs(amount2) >= Math.abs(amount1)) {
            difference = 0;
            percent = 0;
        }
        System.debug('amount1=' + amount1 + ' amount2=' + amount2 + ' balances=' + balances.size() + ' difference=' + difference + ' percent=' + percent);
        for (cb4__CBalance__c balance : balances) {
            balance.cb4__Amount3YTD__c = difference;
            balance.cb4__Amount4YTD__c = percent;
        }
    }*/

    private void nullifyYTDAmounts(List<cb4__CBalance__c> balances) {
        for (cb4__CBalance__c b : balances) {
            b.cb4__Amount1YTD__c = 0;
            b.cb4__Amount2YTD__c = 0;
            b.cb4__Amount3YTD__c = 0;
            b.cb4__Amount4YTD__c = 0;
            b.cb4__Amount5YTD__c = 0;
        }
    }

    private void addYTDValues(cb4__CBalance__c b, cb4__CBalance__c previousBalance) {
        b.cb4__Amount1YTD__c = b.cb4__Amount1__c + (previousBalance == null ? 0 : previousBalance.cb4__Amount1YTD__c);
        b.cb4__Amount2YTD__c = b.cb4__Amount2__c + (previousBalance == null ? 0 : previousBalance.cb4__Amount2YTD__c);
        b.cb4__Amount3YTD__c = b.cb4__Amount3__c + (previousBalance == null ? 0 : previousBalance.cb4__Amount3YTD__c);
        b.cb4__Amount4YTD__c = b.cb4__Amount4__c + (previousBalance == null ? 0 : previousBalance.cb4__Amount4YTD__c);
        b.cb4__Amount5YTD__c = b.cb4__Amount5__c + (previousBalance == null ? 0 : previousBalance.cb4__Amount5YTD__c);
    }
    private void addVarianceValues(cb4__CBalance__c b) {
        b.cb4__Amount3__c = b.cb4__Amount2__c - b.cb4__Amount1__c;
        b.cb4__Amount4__c = (b.cb4__Amount1__c == 0) ? 0 : (b.cb4__Amount2__c / b.cb4__Amount1__c * 100).setScale(0);
        b.cb4__Amount3YTD__c = b.cb4__Amount2YTD__c - b.cb4__Amount1YTD__c; // DIFFERENCE actual - plan
        b.cb4__Amount4YTD__c = (b.cb4__Amount1YTD__c == 0) ? 0 : (b.cb4__Amount2YTD__c / b.cb4__Amount1YTD__c * 100).setScale(0); // PERCENT DIFFERENCE actual / plan * 100
    }

    private static cb4__CBalance__c getNewCBalance(cb4__CBalance__c sb, String pId) {
        cb4__CBalance__c b = sb.clone(false, true, false, false);
        b.cb4__Amount1__c = b.cb4__Amount2__c = b.cb4__Amount3__c = b.cb4__Amount4__c = b.cb4__Amount5__c = b.cb4__Amount1YTD__c = b.cb4__Amount2YTD__c = b.cb4__Amount3YTD__c = b.cb4__Amount4YTD__c = b.cb4__Amount5YTD__c = 0;
        b.cb4__Column__c = pid;
        b.Id = null;
        b.OwnerId = sb.OwnerId;
        return b;
    }

    /**
     *
     *
     * @param periodId any month from the current year
     *
     * @return 12 months. key is period Id and value is cb4__CBTag__c
     */
    private static Map<String, cb4__CBTag__c> getPeriodIds(String periodId) {
        String fyId = [SELECT cb4__Tag1__c FROM cb4__CBTag__c WHERE Id = :periodId LIMIT 1].cb4__Tag1__c;
        Map<String, cb4__CBTag__c> r = new Map<String, cb4__CBTag__c>();
        for (cb4__CBTag__c t : [SELECT Id FROM cb4__CBTag__c WHERE cb4__Tag1__c = :fyId AND cb4__DimensionName__c = 'Period' ORDER BY cb4__OrderNumber__c, Name LIMIT 365]) r.put(t.Id, t);
        return r;
    }

    private static void updateLastUsingDateAndDescription(cb4__CBalanceRule__c balanceRule) {
        if (balanceRule == null) return;
        balanceRule.cb4__LastUse__c = System.today();
        balanceRule.cb4__ChildNumber__c = [SELECT COUNT() FROM cb4__CBalance__c WHERE cb4__CBalanceRule__c = :balanceRule.Id LIMIT 50000];
        update balanceRule;
    }

    /**
     * The main job request
     */
    private String getMainQuery() {
        return 'SELECT cb4__Amount1__c,cb4__Amount2__c,cb4__Amount3__c,cb4__Amount4__c,cb4__Amount5__c,cb4__Column__c,cb4__CBalanceRule__c,OwnerId,' +
                'cb4__Lvl1__c,cb4__Lvl2__c,cb4__Lvl3__c,cb4__Lvl4__c,cb4__Lvl5__c,cb4__Lvl6__c,cb4__Lvl7__c,cb4__DrillDown__c,cb4__Key__c,KeyOwner__c ' +
                'FROM cb4__CBalance__c ' +
                'WHERE cb4__CBalanceRule__c = \'' + CBalanceRuleId + '\' AND cb4__Lvl1__c = \'' + currBrdId + '\' ORDER BY KeyOwner__c ';
    }

}