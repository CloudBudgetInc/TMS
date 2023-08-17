public with sharing class CBRunCalculationRulesProcess  implements Database.Batchable<sObject> {
    private Set<Id> budgetAppIds;
    private List<cb4__CBTag__c> calcRulesSource;
    private static final String accountDimId = cb4.CBUtils.dimensionNameIdMap.get('Account');
    private static final String dimIdSubtype = cb4.CBUtils.dimensionNameIdMap.get('Account Subtype');
    private static final String dimIdType = cb4.CBUtils.dimensionNameIdMap.get('Account Type');
    private static final String periodDimId = cb4.CBUtils.dimensionNameIdMap.get('Period');
    private static final String accountSetDimId = cb4.CBUtils.dimensionNameIdMap.get('Account Set');
    private static final String periodSetDimId = cb4.CBUtils.dimensionNameIdMap.get('Period Set');
    private static Map<Id, Set<Id>> BYMap {
        get {
            if (BYMap == null) {
                BYMap = new Map<Id, Set<Id>>();
                for (cb4__CBTag__c t : cb4.CBController.getTagListServer(periodDimId, null, null, null, false, null, null, null)) {
                    Set<Id> p = BYMap.get(t.cb4__Tag1__c);
                    if (p == null) {
                        p = new Set<Id>();
                        BYMap.put(t.cb4__Tag1__c, p);
                    }
                    p.add(t.Id);
                }
            }
            return BYMap;
        }
        set;
    }

    private static Map<Id, Set<Id>> setMap {
        get {
            if (setMap == null)setMap = getMapOfRelatedAccountsInSet();
            return setMap;
        }
        set;
    }

    public static Map<Id, cb4__CBTag__c> accountMap {
        get {
            if (accountMap == null) {
                accountMap = new Map<Id, cb4__CBTag__c>();
                for (cb4__CBTag__c t : cb4.CBController.getTagListServer(accountDimId, null, null, null, false, ' cb4__Tag1__r.cb4__Tag1Name__c ', null, null)) accountMap.put(t.Id, t);
            }
            return accountMap;
        }
        set;
    }

    public CBRunCalculationRulesProcess(Set<Id> bAppIds) {
        this.budgetAppIds = bAppIds;
        this.calcRulesSource = Database.query('SELECT ' + cb4.CBUtils.getAllSObjectFields('cb4__CBTag__c', 'cb4__Tag3__r.cb4__Dimension__r.cb4__isSet__c, cb4__Tag1__r.cb4__Dimension__r.cb4__isSet__c') + ' WHERE cb4__DimensionName__c = \'Calculation Rule\'');
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT ' + cb4.CBUtils.getAllSObjectFields('cb4__CBTag__c', 'cb4__Tag1__r.cb4__Tag2__r.cb4__Tag4__c') + ' WHERE cb4__Tag1__c IN :budgetAppIds AND cb4__Text5__c != \'calcRule\'');
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<cb4__CBTag__c> newCalculatedAmounts = generateCRSyntheticTags(calcRulesSource, (List<cb4__CBTag__c>) scope, null, null);
        insert newCalculatedAmounts;
    }

    public void finish(Database.BatchableContext BC) {

    }

    public static List<cb4__CBTag__c> generateCRSyntheticTags(List<cb4__CBTag__c> calcRules, List<cb4__CBTag__c> srcTags, List<cb4__CBTag__c> totalTags, Map<Id, Product2> productMap) {
        List<cb4__CBTag__c> r = new List<cb4__CBTag__c> ();
        Map<String, cb4__CBTag__c> resultRulesMap = getMapIdResultCalcRules(calcRules); // key => Id of source calc rule  , value => result calc rule

        for (cb4__CBTag__c cr : calcRules) {
            String crAccType;
            String crAccName;
            cb4__CBTag__c resultCR = resultRulesMap.get(cr.cb4__Tag2__c);
            Boolean isTotalLinesCalcRule = cr.cb4__Text3__c == 'Total Income' || cr.cb4__Text3__c == 'Total Expense' || cr.cb4__Text3__c == 'Total Margin';
            String totalType = '';
            if (isTotalLinesCalcRule) {
                totalType = cr.cb4__Text3__c.replace('Total ', '');
                srcTags = totalTags;
            }

            // Expense or Income lines
            for (cb4__CBTag__c t : srcTags) { // t is source cb4__CBTag__c

                Boolean simpleLinesConditionIsOk = !isTotalLinesCalcRule && periodTheSame(cr, t) && accountTheSame(cr, t) && dimensionsTheSame(cr, t);
                Boolean totalLinesConditionIsOk = isTotalLinesCalcRule && t.cb4__Text3__c == totalType && periodTheSame(cr, t);

                if (simpleLinesConditionIsOk || totalLinesConditionIsOk) {
                    if (resultCR.cb4__Boolean6__c == true) resultCR.cb4__Tag1__c = t.cb4__Tag2__c; // if you need to save account from source tag

                    crAccType = crAccType == null ? accountMap.get(resultCR.cb4__Tag1__c).cb4__Tag1__r.cb4__Tag1Name__c : crAccType;
                    crAccName = crAccName == null ? accountMap.get(resultCR.cb4__Tag1__c).cb4__TagLabel__c : crAccName;
                    cb4__CBTag__c s = t.clone(); // new synthetic CBTag
                    Product2 product = s.cb4__Product__c == null ? null : productMap.get(s.cb4__Product__c);
                    s.cb4__Text1__c = s.cb4__Text2__c = crAccType.toLowerCase(); // type income OR expense
                    s.cb4__Text3__c = crAccName; // title
                    s.cb4__Text4__c = 'Created by Calculation Rule "' + cr.cb4__TagLabel__c + '". Source line is "' + t.cb4__Text3__c + '".'; // Row Description
                    s.cb4__Text4__c += product == null ? '' : ' Product is "' + product.Name + '".';
                    s.cb4__Text5__c = 'calcRule'; // calcRule style
                    s.cb4__Text6__c = cr.Name; // Calc rule name
                    s.cb4__Text7__c = t.Name; // Source line Name
                    s.cb4__Tag2__c = resultCR.cb4__Tag1__c; // account Id
                    s.cb4__Tag5__c = null; // Rate
                    s.cb4__Tag6__c = resultCR.cb4__Boolean1__c == true ? t.cb4__Tag6__c : resultCR.cb4__Tag6__c;
                    s.cb4__Tag7__c = resultCR.cb4__Boolean2__c == true ? t.cb4__Tag7__c : resultCR.cb4__Tag7__c;
                    s.cb4__Tag8__c = resultCR.cb4__Boolean3__c == true ? t.cb4__Tag8__c : resultCR.cb4__Tag8__c;
                    s.cb4__Tag9__c = resultCR.cb4__Boolean4__c == true ? t.cb4__Tag9__c : resultCR.cb4__Tag9__c;
                    s.cb4__Tag10__c = resultCR.cb4__Boolean5__c == true ? t.cb4__Tag10__c : resultCR.cb4__Tag10__c;
                    s.cb4__Decimal1__c = calculateSyntheticValueWithSourceRule(cr, t); // calculated from source CR
                    s.cb4__Decimal1__c = calculateSyntheticValueWithResultRule(resultCR, s.cb4__Decimal1__c); // specified from result CR
                    s.cb4__Decimal2__c = s.cb4__Decimal3__c = 0;
                    s.cb4__PriceBook__c = null;
                    s.cb4__ExtId__c = t.Id;
                    r.add(s);
                }
            }

        }
        return r;
    }

    private static Map<String, cb4__CBTag__c> getMapIdResultCalcRules(List<cb4__CBTag__c> srcTags) {
        Set<Id> resRuleIds = new Set<Id>();
        Map<String, cb4__CBTag__c> r = new Map<String, cb4__CBTag__c>();
        for (cb4__CBTag__c t : srcTags) resRuleIds.add(t.cb4__Tag2__c);
        for (cb4__CBTag__c t : [SELECT Id,cb4__Tag1__c,cb4__Tag2__c,cb4__Tag3__c,cb4__Tag4__c,cb4__Tag5__c,cb4__Tag6__c,cb4__Tag7__c,cb4__Tag8__c,cb4__Tag9__c,cb4__Tag10__c,cb4__Decimal1__c,cb4__Decimal2__c,cb4__Decimal3__c,cb4__Boolean1__c,cb4__Boolean2__c,cb4__Boolean3__c,cb4__Boolean4__c,cb4__Boolean5__c,cb4__Boolean6__c FROM cb4__CBTag__c WHERE Id IN:resRuleIds AND cb4__DimensionName__c = 'Calculation Rule']) r.put(t.Id, t);
        return r;
    }

    private static Boolean periodTheSame(cb4__CBTag__c cr, cb4__CBTag__c t) {
        if (cr.cb4__Tag3__r.cb4__Dimension__r.cb4__isSet__c) return setContainsTag(cr.cb4__Tag3__c, t.cb4__Tag3__c); // if period is set
        return cr.cb4__Tag3__c == t.cb4__Tag3__c || (BYMap.keySet().contains(cr.cb4__Tag3__c) && BYMap.get(cr.cb4__Tag3__c).contains(t.cb4__Tag3__c)); // if period is month or BY
    }

    private static Boolean accountTheSame(cb4__CBTag__c cr, cb4__CBTag__c t) {
        if (cr.cb4__Tag1__r.cb4__Dimension__r.cb4__isSet__c) return setContainsTag(cr.cb4__Tag1__c, t.cb4__Tag2__c);
        return cr.cb4__Tag1__c == t.cb4__Tag2__c;
    }

    private static Boolean dimensionsTheSame(cb4__CBTag__c cr, cb4__CBTag__c t) {
        if (cr.cb4__Tag6__c != null && cr.cb4__Tag6__c != t.cb4__Tag6__c) return false;
        if (cr.cb4__Tag7__c != null && cr.cb4__Tag7__c != t.cb4__Tag7__c) return false;
        if (cr.cb4__Tag8__c != null && cr.cb4__Tag8__c != t.cb4__Tag8__c) return false;
        if (cr.cb4__Tag9__c != null && cr.cb4__Tag9__c != t.cb4__Tag9__c) return false;
        if (cr.cb4__Tag10__c != null && cr.cb4__Tag10__c != t.cb4__Tag10__c) return false;
        return true;
    }

    private static Boolean setContainsTag(Id setId, Id examId) {
        Set<Id> s = setMap.get(setId);
        if (s == null) return false;
        return s.contains(examId);
    }

    private static Map<Id, Set<Id>> getMapOfRelatedAccountsInSet() {
        Map<Id, Set<Id>> r = new Map<Id, Set<Id>>();
        Set<Id> accountPeriodSetIds = new Set<Id>();
        for (cb4__CBTag__c t : [SELECT Id FROM cb4__CBTag__c WHERE cb4__Dimension__c = :accountSetDimId OR cb4__Dimension__c = :periodSetDimId]) accountPeriodSetIds.add(t.Id);
        for (cb4__CBLink__c t : [SELECT cb4__Tag1__c, cb4__Tag2__c FROM cb4__CBLink__c WHERE cb4__Type__c = 'Set' AND cb4__Tag1__c = :accountPeriodSetIds LIMIT 50000]) {
            Set<Id> bunch = r.get(t.cb4__Tag1__c);
            if (bunch == null) bunch = new Set<Id>{
                    t.cb4__Tag2__c
            }; else bunch.add(t.cb4__Tag2__c);
            r.put(t.cb4__Tag1__c, bunch);
        }
        return r;
    }

    private static Decimal calculateSyntheticValueWithResultRule(cb4__CBTag__c cr, Decimal val) {
        if (cr.cb4__Decimal1__c != null && cr.cb4__Decimal1__c != 0) return cr.cb4__Decimal1__c;
        if (cr.cb4__Decimal2__c != null && cr.cb4__Decimal1__c != 0 && val > cr.cb4__Decimal2__c) return cr.cb4__Decimal2__c;
        if (cr.cb4__Decimal3__c != null && cr.cb4__Decimal1__c != 0 && val < cr.cb4__Decimal3__c) return cr.cb4__Decimal3__c;
        return val;
    }

    private static Decimal calculateSyntheticValueWithSourceRule(cb4__CBTag__c cr, cb4__CBTag__c t) {
        String relation = cr.cb4__Text2__c;
        Decimal rate = cr.cb4__Decimal1__c;
        Decimal srcValue = cr.cb4__Boolean1__c ? -(t.cb4__Decimal1__c) : t.cb4__Decimal1__c;

        switch on relation {
            when 'Percent' {
                return srcValue * rate / 100;
            }
            when 'Multiply' {
                return srcValue * rate;
            }
            when 'Add' {
                return srcValue + rate;
            }
            when else {
                return -1;
            }
        }
    }

}