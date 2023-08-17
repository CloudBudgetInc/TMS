/**
 * Created by Alex JR on 8/17/2020.
 */

public with sharing class CBBudgetsAndBalancesToBudgetAppConverter {

    private static final Map<String, String> bbTypeMap = new Map<String, String>{
            'Operating Expenses' => 'expense',
            'Depreciation and Amortization' => 'expense',
            'Gross Profit' => 'income'
    };
    private static final Id budgetAppAmountDimensionId = [SELECT Id FROM cb4__CBDimension__c WHERE Name = 'Budget App Amount' LIMIT 1].Id;


    public static void runConversion() {
        List<c2g__codaBudget__c> bb = getBudgetAndBalances();
        List<cb4__CBTag__c> bAppAmounts = getBudgetAppAmountsFromBudgetsAndBalances(bb);

        System.debug(bAppAmounts.size());
        insert bAppAmounts;
        //insert bAppAmounts;
    }


    private static List<c2g__codaBudget__c> getBudgetAndBalances() {
        String q = 'SELECT  Id,Name,c2g__ActualPeriod001__c,c2g__ActualPeriod002__c,c2g__ActualPeriod003__c,c2g__ActualPeriod004__c,c2g__ActualPeriod005__c,' +
                'c2g__ActualPeriod006__c,c2g__ActualPeriod007__c,c2g__ActualPeriod008__c,c2g__ActualPeriod009__c,c2g__ActualPeriod010__c,' +
                'c2g__ActualPeriod011__c,c2g__ActualPeriod012__c,Budget_Reporting_Department_2__c,Budget_Reporting_Department_3__c,Budget_Reporting_Department__c,' +
                'c2g__Dimension1__c,c2g__Dimension2__c,c2g__Dimension3__c,c2g__Dimension4__c,c2g__GeneralLedgerAccount__c,c2g__GeneralLedgerAccount__r.c2g__TrialBalance2__c';
        String f = ' FROM c2g__codaBudget__c';
        String w = ' WHERE c2g__Year__r.Name = \'2020\' AND c2g__GeneralLedgerAccount__r.c2g__Type__c = \'Profit and Loss\' ' +
                ' AND c2g__Dimension2__c != null AND c2g__Dimension1__c != null ';
        String l = ' ORDER BY Name LIMIT 10000 OFFSET 2000';
        return Database.query(q + f + w + l);
    }

    private static List<cb4__CBTag__c> getBudgetAppAmountsFromBudgetsAndBalances(List<c2g__codaBudget__c> source) {
        List<cb4__CBTag__c> r = new List<cb4__CBTag__c>();

        Map<String, Id> dimMap = getDimensionsMap();
        Map<Decimal, Id> periodMap = getPeriodMap();
        Map<String, Id> budgetAppMap = getBudgetAppMap();
        Map<String, String> lineTitle1Map = getLineTitle1Map();
        Map<String, String> lineTitle2Map = getLineTitle2Map();

        for (c2g__codaBudget__c bb : source) {
            String acc = dimMap.get(bb.c2g__GeneralLedgerAccount__c);
            String ff2 = dimMap.get(bb.c2g__Dimension2__c);
            String app = budgetAppMap.get(ff2);
            String type = bbTypeMap.get(bb.c2g__GeneralLedgerAccount__r.c2g__TrialBalance2__c);
            if (app == null || acc == null || ff2 == null || type == null) continue;

            String ff1 = dimMap.get(bb.c2g__Dimension1__c);
            String ff3 = dimMap.get(bb.c2g__Dimension3__c);
            String ff4 = dimMap.get(bb.c2g__Dimension4__c);

            for (Integer i = 1; i <= 12; i++) {
                Decimal val = (Decimal) bb.get('c2g__ActualPeriod' + (i < 10 ? '00' + i : '0' + i) + '__c');
                Id period = periodMap.get(i);
                if (val == 0 || period == null) continue;

                String ff1Name = lineTitle2Map.get(ff1);
                String title = lineTitle1Map.get(acc) + (ff1Name == null ? '' : ' : ' + ff1Name);
                cb4__CBTag__c bAppAmount = new cb4__CBTag__c(
                        cb4__Dimension__c = budgetAppAmountDimensionId,
                        cb4__Decimal1__c = type == 'income' ? val * -1 : val,
                        cb4__Decimal2__c = 0,
                        cb4__Decimal3__c = 0,
                        cb4__Text1__c = type,
                        cb4__Text2__c = type,
                        cb4__Text3__c = title,
                        cb4__Tag1__c = app,
                        cb4__Tag2__c = acc,
                        cb4__Tag3__c = period,
                        cb4__Tag6__c = ff1,
                        cb4__Tag7__c = ff3,
                        cb4__Tag8__c = ff4,
                        cb4__ExtId__c = bb.Id,
                        cb4__Text4__c = 'Imported from the Budget App Amounts'
                );
                r.add(bAppAmount);
            }

        }
        return r;
    }

    private static Map<String, Id> getDimensionsMap() {
        Map<String, Id> r = new Map<String, Id>();
        for (cb4__CBTag__c t : [
                SELECT Id, cb4__ExtId__c
                FROM cb4__CBTag__c
                WHERE (cb4__DimensionName__c = 'CB_FF1' OR cb4__DimensionName__c = 'CB_FF2' OR cb4__DimensionName__c = 'CB_FF3'
                OR cb4__DimensionName__c = 'CB_FF4' OR cb4__DimensionName__c = 'Account') AND cb4__ExtId__c != null
        ])r.put(t.cb4__ExtId__c, t.Id);
        return r;
    }

    private static Map<Decimal, Id> getPeriodMap() {
        Map<Decimal, Id> r = new Map<Decimal, Id>();
        for (cb4__CBTag__c t : [SELECT Id, cb4__OrderNumber__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Period' AND cb4__Tag1Name__c = '2020']) {
            r.put(t.cb4__OrderNumber__c, t.Id);
        }
        return r;
    }

    private static Map<String, Id> getBudgetAppMap() {
        Map<String, Id> r = new Map<String, Id>();
        for (cb4__CBTag__c t : [SELECT Id, cb4__Tag7__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Budget App' AND cb4__Tag7__c != null])
            r.put(t.cb4__Tag7__c, t.Id);
        return r;
    }

    private static Map<String, String> getLineTitle1Map() {
        Map<String, String> r = new Map<String, String>();
        for (cb4__CBTag__c t : [SELECT Id, Name FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Account'])r.put(t.Id, t.Name);
        return r;
    }
    private static Map<String, String> getLineTitle2Map() {
        Map<String, String> r = new Map<String, String>();
        for (cb4__CBTag__c t : [SELECT Id, Name FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'CB_FF1'])r.put(t.Id, t.Name);
        return r;
    }

    public static void deleteObsoleteBudgetAppAmounts() {
        delete [SELECT Id FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Budget App Amount' AND cb4__ExtId__c != null LIMIT 10000];
        //delete [SELECT Id FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Budget App Amount' AND cb4__ExtId__c != null LIMIT 10000];
    }

}