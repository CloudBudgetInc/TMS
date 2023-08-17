/**
 * Created by Alex JR on 8/17/2020.
 * The job controller for generating CBalances for the three level reports
 * Jobs are performing in an queue (1th, 2nd, 3rd level) for specified financial year
 * The main method for running is  public static void runJobs()
 */

public with sharing class CBalanceGenerator implements Database.Batchable<SObject> {

    private static final String brdName = 'Budget Reporting Department';
    private static final String NA = 'XXXXXXXXXXXXXXXXXX';
    private static final Id budgetReportingDepartmentDimensionId = [SELECT Id FROM cb4__CBDimension__c WHERE Name = :brdName LIMIT 1].Id;
    private static final String financialYear = CBVariable.currentFY;
    private static final Id financialYearId = [SELECT Id FROM cb4__CBTag__c WHERE cb4__Dimension__c = :cb4.CBUtils.dimensionNameIdMap.get('Budget Year') AND Name = :CBVariable.currentFY LIMIT 1][0].Id;
    private Integer lvl;
    private static final String ruleNameMark = 'LVL'; // CBalance rule should contain this string
    public cb4__CBalanceRule__c CBRule;
    private static final String typeOfPositiveSign = 'expense';
    /**
     * The name of class that will initiate after the last job completed. 
     */
    private String afterJobClassName;

    public CBalanceGenerator() {
    }

    public CBalanceGenerator(Integer lvl, String afterJobClassName) {
        this.lvl = lvl;
        this.afterJobClassName = afterJobClassName;
        CBRule = Database.query('SELECT Id FROM cb4__CBalanceRule__c WHERE (cb4__Label__c LIKE \'%' + ruleNameMark + String.valueOf(lvl) + '%\' AND cb4__Label__c LIKE \'%' + financialYear + '%\' ) LIMIT 1');
    }

    public static void runJobs(String afterJobClassName) {
        Set<String> ruleIds = new Set<String>();
        String q = 'SELECT Id FROM cb4__CBalanceRule__c WHERE (cb4__Label__c LIKE \'%' + ruleNameMark + '%\' AND cb4__Label__c LIKE \'%' + financialYear + '%\' )';
        for (cb4__CBalanceRule__c r : Database.query(q)) ruleIds.add(r.Id);
        CBalanceGenerator lp = new CBalanceGenerator(1, afterJobClassName);
        Map<String, String> sMap = new Map<String, String>{
                'custom' => ' cb4__CBalanceRule__c IN ' + cb4.CBUtils.getFormattedINQuery(ruleIds)
        };
        cb4.CBDeleteJob dj = new cb4.CBDeleteJob('cb4__CBalance__c', sMap, lp, 2000);
        Id batchId = Database.executeBatch(dj, 2000);
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        String q = 'SELECT cb4__Tag1__c,cb4__Tag2__c,cb4__Tag3__c,cb4__Tag6__c,cb4__Tag7__c,cb4__Tag8__c,cb4__Tag9__c,cb4__Tag1__r.cb4__Tag9__c,' +
                'cb4__Tag1__r.cb4__Tag7__c, cb4__Tag1__r.cb4__Tag6__c, cb4__Decimal1__c,' +
                'cb4__Tag2__r.cb4__Tag1__r.cb4__Tag1__c,cb4__Tag2__r.cb4__Tag1__c, cb4__Tag1__r.cb4__Tag8Name__c, ' +
                'cb4__Tag2__r.cb4__Tag1__r.cb4__Tag1Name__c,cb4__Tag1__r.cb4__Tag4Name__c,OwnerId ' +
                'FROM cb4__CBTag__c ' +
                'WHERE cb4__Dimension__c = \'' + cb4.CBUtils.dimensionNameIdMap.get('Entry Amount') + '\' ' +
                ' AND (NOT cb4__Tag2__r.cb4__Tag1Name__c like \'%Amort%\') AND (NOT cb4__Tag2__r.cb4__Tag1Name__c like \'%Allocated CS Cost%\') ' + // exclude amortization
                ' AND cb4__Decimal1__c != 0' + // exclude empty values
                ' AND cb4__Text1__c = \'main\'  ' + // exclude balance
                'AND cb4__Tag1__r.cb4__Tag1__c = \'' + financialYearId + '\'  ';
        return Database.getQueryLocator(q);
    }
    public void execute(Database.BatchableContext context, List<cb4__CBTag__c> scope) {
        insertCBalances(scope);
    }
    public void finish(Database.BatchableContext context) {
        insert new cb4__CBLog__c (cb4__Type__c = 'OTHER', cb4__Description__c = 'RUN CBalanceYTDandVariance CBRule.Id = ' + CBRule.Id);
        Id jobYTDId = Database.executeBatch(new CBalanceYTDandVariance(CBRule.Id), 830); // 830 is 10k/12

        if (lvl == 3) {
            if (afterJobClassName != null) (Type.forName(afterJobClassName)).newInstance(); // run constructor of after job class
        } else {
            Id jobNextId = Database.executeBatch(new CBalanceGenerator(lvl + 1, afterJobClassName), 2000);
            //Boolean isSuccess = System.FlexQueue.moveJobToEnd(jobYTDId);
        }
    }

    public void insertCBalances(List<cb4__CBTag__c> scope) {
        Map<String, cb4__CBalance__c> r = new Map<String, cb4__CBalance__c>(); // key - cb2_brd, value CBalance
        for (cb4__CBalance__c balance : Database.query(getMainQuery())) r.put(balance.cb4__Column__c + balance.cb4__Key__c + balance.OwnerId, balance);
        Map<String, cb4__CBalance__c> CBalancesNeedToUpsert = new Map<String, cb4__CBalance__c>(); // New CBalance Container
        Map<String, String> bridgeDim1Dim2Map = CBService.getBridgeDim1Dim2Map(lvl);

        for (cb4__CBTag__c ea : scope) { // Entry Amounts
            String CB2BRD = bridgeDim1Dim2Map.get(ea.cb4__Tag6__c + String.valueOf(ea.cb4__Tag7__c)); // FF1 and FF2
            if (CB2BRD == null) continue;
            String key = getCBalanceKey(CB2BRD, ea);
            cb4__CBalance__c balance = r.get(ea.cb4__Tag3__c + key + ea.OwnerId);
            if (balance == null) balance = new cb4__CBalance__c(
                    cb4__CBalanceRule__c = CBRule.Id,
                    cb4__Lvl1__c = CB2BRD,// Reporting Department
                    cb4__Lvl2__c = ea.cb4__Tag2__r.cb4__Tag1__r.cb4__Tag1__c,
                    cb4__Lvl3__c = ea.cb4__Tag2__r.cb4__Tag1__c,
                    cb4__Lvl4__c = ea.cb4__Tag2__c,
                    cb4__Column__c = ea.cb4__Tag3__c,
                    cb4__Amount1__c = 0,
                    cb4__Amount2__c = 0,
                    cb4__Amount3__c = 0,
                    cb4__Amount4__c = 0,
                    cb4__Amount5__c = 0,
                    cb4__Key__c = key,
                    OwnerId = ea.OwnerId
            );

            balance = addDrillDownLink(balance, ea);
            Decimal amount = (ea.cb4__Tag2__r.cb4__Tag1__r.cb4__Tag1Name__c == typeOfPositiveSign ? ea.cb4__Decimal1__c * -1 : ea.cb4__Decimal1__c);
            if (ea.cb4__Tag1__r.cb4__Tag4Name__c == 'Actual') {
                balance.cb4__Amount2__c += amount;
            } else {
                if (ea.cb4__Tag1__r.cb4__Tag8Name__c == 'Base') balance.cb4__Amount1__c += amount; else balance.cb4__Amount5__c += amount;
            }
            r.put(ea.cb4__Tag3__c + key + ea.OwnerId, balance);
            CBalancesNeedToUpsert.put(ea.cb4__Tag3__c + key + ea.OwnerId, balance);
        }
        upsert CBalancesNeedToUpsert.values();

        CBRule.cb4__ChildNumber__c = [SELECT COUNT() FROM cb4__CBalance__c WHERE cb4__CBalanceRule__c = :CBRule.Id];
        update CBRule;
    }

    private static cb4__CBalance__c addDrillDownLink(cb4__CBalance__c cb, cb4__CBTag__c tag) {
        String exId = tag.cb4__Tag1__c;
        if (cb.cb4__DrillDown__c == null || cb.cb4__DrillDown__c == '') {
            cb.cb4__DrillDown__c = exId;
        } else {
            if (cb.cb4__DrillDown__c.length() >= 30960) return cb; // Long text field cannot contain more than 1724 Ids
            List<String> idList = cb.cb4__DrillDown__c.split(',');
            if (!idList.contains(exId)) cb.cb4__DrillDown__c += ',' + exId;
        }
        return cb;
    }

    /**
     * @param CB2BRD CB - Budget Reporting Department Id
     * @param ea - Entry Amount
     *
     * @return
     */
    private static String getCBalanceKey(String CB2BRD, cb4__CBTag__c ea) {
        List<String> p = new List<String>{
                CB2BRD, // Budget Reporting Department
                ea.cb4__Tag2__r.cb4__Tag1__r.cb4__Tag1__c, // Account Type
                ea.cb4__Tag2__r.cb4__Tag1__c, // Account Sub Type
                ea.cb4__Tag2__c //Account
                /*ea.cb4__Tag1__r.cb4__Tag9__c*/ // BDG
        };
        return String.join(p, '');
    }

    private String getMainQuery() {
        return 'SELECT cb4__Amount1__c,cb4__Amount2__c,cb4__Amount3__c,cb4__Amount4__c,cb4__Amount5__c,cb4__Key__c,cb4__Column__c,' +
                'cb4__CBalanceRule__c,OwnerId,' +
                'cb4__Lvl1__c,cb4__Lvl2__c,cb4__Lvl3__c,cb4__Lvl4__c,cb4__Lvl5__c,cb4__Lvl6__c,cb4__Lvl7__c,cb4__DrillDown__c ' +
                'FROM cb4__CBalance__c ' +
                'WHERE cb4__CBalanceRule__c = \'' + CBRule.Id + '\' ORDER BY cb4__Key__c ';
    }
}