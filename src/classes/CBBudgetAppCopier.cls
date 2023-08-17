/**
 * Created by Alex JR on 9/10/2020.
 * This class is for copying Budget Apps Structure to the next finance year of to forecast
 *
 * !! ONLY BUDGET APP WITH LINES WILL COPIED
 */

public with sharing class CBBudgetAppCopier implements Database.Batchable<SObject> {

    private String afterJobClassName;
    private String sourceType; //   COPY   ||   FORECAST
    private String sourceFYId;
    private String targetType; //   COPY   ||   FORECAST
    private String targetFYId;
    private static final String specialLabel = 'COPIED';
    private Map<String, String> monthsMap;
    private static final Id budgetAppDimensionId = [SELECT Id FROM cb4__CBDimension__c WHERE Name = 'Budget App' LIMIT 1].Id;
    private static final Id budgetAppAmountDimensionId = [SELECT Id FROM cb4__CBDimension__c WHERE Name = 'Budget App Amount' LIMIT 1].Id;
    private static final Id periodDimensionId = [SELECT Id FROM cb4__CBDimension__c WHERE Name = 'Period' LIMIT 1].Id;
    private static final Id baseTagId = [SELECT Id FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Scenario' AND Name = 'Base' LIMIT 1].Id;
    private static final Id forecastTagId = [SELECT Id FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Scenario' AND Name = 'Forecast' LIMIT 1].Id;

    /**
    * sourceType, sourceYear, targetType, targetYear, null
     * @param sourceType   "BASE"   ||   "FORECAST"
     * @param sourceFY  "2022"
     * @param targetFY  "2023"
     * @param afterJobClassName  null   ||   "any name of a step"
     */
    public static void runJob(String sourceType, String sourceFY, String targetType, String targetFY, String afterJobClassName) {
        /* System.debug('sourceType=' + sourceType);
         System.debug('sourceFY=' + sourceFY);
         System.debug('targetType=' + targetType);
         System.debug('targetFY=' + targetFY);*/

        if ((sourceType != 'BASE' && sourceType != 'FORECAST') || (targetType != 'BASE' && targetType != 'FORECAST') || sourceFY == null || targetFY == null) return;
        if (alreadyDone(targetType, targetFY)) return;

        CBBudgetAppCopier dj = new CBBudgetAppCopier(sourceType, sourceFY, targetType, targetFY, afterJobClassName);
        Id batchId = Database.executeBatch(dj, 2000);
    }

    /**
     * DO NOT USE
     * Use the "runJob" method
     */
    public CBBudgetAppCopier(String sourceType, String sourceFY, String targetType, String targetFY, String afterJobClassName) {
        this.sourceType = sourceType;
        this.sourceFYId = [SELECT Id FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Budget Year' AND Name = :sourceFY LIMIT 1][0].Id;
        this.targetType = targetType;
        this.targetFYId = [SELECT Id FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Budget Year' AND Name = :targetFY LIMIT 1][0].Id;
        this.afterJobClassName = afterJobClassName;
        this.monthsMap = getMonthsMap(sourceFYId, targetFYId); // key - source period, value - target period

        insertBudgetAppStructure(sourceType, sourceFY, targetType, targetFY);
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        String q = 'SELECT  cb4__Tag1__c,cb4__Tag2__c,cb4__Tag3__c,cb4__Tag4__c,cb4__Tag5__c,cb4__Tag6__c,cb4__Tag7__c,cb4__Tag8__c,cb4__Tag9__c,cb4__Tag10__c,' +
                'cb4__Tag1__r.cb4__Tag1__c,cb4__Tag1__r.cb4__Tag2__c,cb4__Tag1__r.cb4__Tag3__c,cb4__Tag1__r.cb4__Tag4__c,cb4__Tag1__r.cb4__Tag6__c,' +
                'cb4__Tag1__r.cb4__Tag7__c,cb4__Tag1__r.cb4__Tag8__c,cb4__Tag1__r.cb4__Tag9__c,cb4__Tag1__r.cb4__Tag10__c,cb4__Tag1__r.Name,' +
                'cb4__Decimal1__c,cb4__Text1__c,cb4__Text2__c,cb4__Text3__c,OwnerId,cb4__Tag1__r.OwnerId ' +
                'FROM cb4__CBTag__c ' +
                'WHERE cb4__DimensionName__c = \'Budget App Amount\' AND cb4__Tag1__r.cb4__Tag8Name__c = \'' + sourceType + '\'   ' +
                'AND cb4__Tag1__r.cb4__Tag3__c = \'' + sourceFYId + '\'  ';
        logJobStart(q);
        return Database.getQueryLocator(q);
    }

    public void execute(Database.BatchableContext context, List<cb4__CBTag__c> scope) {
        cb4.CBConsole.setLog('OTHER', 'Budget Copy Job Execution', 'job execution report');
        cb4.CBConsole.addLog('@B-> Source type: ' + sourceType + ' Source BY Id: ' + sourceFYId + ' Target type: ' + targetType + ' Target BY Id: ' + targetFYId + ' job execution');
        cb4.CBConsole.insertLog();
        insertAppLines(scope, monthsMap);
    }
    public void finish(Database.BatchableContext context) {
        removeOldExtIdFromApps();
        if (afterJobClassName != null) (Type.forName(afterJobClassName)).newInstance();
    }

    private static void logJobStart(String mainQuery) {
        cb4.CBConsole.setLog('OTHER', 'Budget Copy Job Started', 'job start report');
        cb4.CBConsole.addLog('@B->  Job query = ' + mainQuery);
        cb4.CBConsole.insertLog();
    }

    /**
     * Architecture:
     cb4__Tag1__c - parent BA
     cb4__Tag2__c - templategetRowsServer
     cb4__Tag3__c - main period (BY)
     cb4__Tag4__c - Department
     cb4__Decimal1__c - Total Income
     cb4__Decimal2__c - Total Expense
     cb4__Decimal6__c - Split Row
     cb4__Text3__c - Description
     cb4__Text5__c - Clone Key
     *
     * @param sourceType
     * @param sourceYear
     * @param targetType
     * @param targetYear
     */

    public void insertBudgetAppStructure(String sourceType, String sourceYear, String targetType, String targetYear) {
        List<cb4__CBTag__c> newApps = new List<cb4__CBTag__c>();
        Map<String, String> baseAppAndParentMap = new Map<String, String>(); // key = base App Id;  value - its parent Id;
        Map<String, String> newAppAndBaseAppMap = new Map<String, String>(); // key = new App Id;   value - base App Id;
        Map<String, String> baseAppToNewAppMap = new Map<String, String>(); // key = base AppId;   value - new App Id;
        Map<String, String> baseAppAndParent = new Map<String, String>(); // key = base App Id , parent = its parent App Id

        for (cb4__CBTag__c baseApp : [
                SELECT Id, Name, cb4__Text3__c, cb4__Tag1__c, cb4__Tag2__c, cb4__Tag3__c, cb4__Tag4__c, cb4__Tag6__c, cb4__Tag7__c,
                        cb4__Tag8__c, cb4__Tag9__c, cb4__Tag10__c, cb4__Dimension__c, OwnerId
                FROM cb4__CBTag__c
                WHERE cb4__Dimension__c = :budgetAppDimensionId AND cb4__Tag8Name__c = :sourceType AND cb4__Tag3Name__c = :sourceYear
        ]) {
            cb4__CBTag__c newApp = baseApp.clone(false, true, false, false);
            newApp.Id = null;
           // newApp.Name += ' FCST';
            newApp.cb4__Tag3__c = targetFYId;
            newApp.cb4__Tag8__c = targetType == 'BASE' ? baseTagId : forecastTagId;
            newApp.cb4__ExtId__c = baseApp.Id;
            newApp.cb4__Text5__c = 'TEST ' + specialLabel;
            newApp.cb4__Status__c = 'Open';
            newApp.cb4__Decimal6__c = 0;
            newApps.add(newApp);
            baseAppAndParentMap.put(baseApp.Id, baseApp.cb4__Tag1__c);
            baseAppAndParent.put(baseApp.Id, baseApp.cb4__Tag1__c);
        }

        insert newApps;

        for (cb4__CBTag__c newApp : newApps) baseAppToNewAppMap.put(newApp.cb4__ExtId__c, newApp.Id);


        for (cb4__CBTag__c newApp : newApps) {
            String baseAppId = newApp.cb4__ExtId__c;
            String baseAppParentId = baseAppAndParent.get(baseAppId);
            String newAppParentId = baseAppToNewAppMap.get(baseAppParentId);
            if (newAppParentId != null) newApp.cb4__Tag1__c = newAppParentId;
        }

        update newApps;
    }

    private static void insertAppLines(List<cb4__CBTag__c> scope, Map<String, String> monthsMap) {
        List<cb4__CBTag__c> newAmounts = new List<cb4__CBTag__c>();
        Map<String, String> sourceAppToNewAppMap = getSourceAppToNewAppMap();

        for (cb4__CBTag__c a : scope) {
            String appId = sourceAppToNewAppMap.get(a.cb4__Tag1__c);
            if (appId == null) continue;
            cb4__CBTag__c newA = new cb4__CBTag__c (
                    cb4__Dimension__c = budgetAppAmountDimensionId,
                    cb4__Tag1__c = appId,
                    cb4__Decimal1__c = a.cb4__Decimal1__c,
                    cb4__Decimal2__c = 0,
                    cb4__Decimal3__c = 0,
                    cb4__Text1__c = a.cb4__Text1__c,
                    cb4__Text2__c = a.cb4__Text2__c,
                    cb4__Text3__c = a.cb4__Text3__c,
                    cb4__Text5__c = specialLabel,
                    cb4__Tag2__c = a.cb4__Tag2__c,
                    cb4__Tag3__c = monthsMap.get(a.cb4__Tag3__c),
                    cb4__Tag4__c = a.cb4__Tag4__c,
                    cb4__Tag5__c = a.cb4__Tag5__c,
                    cb4__Tag6__c = a.cb4__Tag6__c,
                    cb4__Tag7__c = a.cb4__Tag7__c,
                    cb4__Tag8__c = a.cb4__Tag8__c,
                    cb4__Tag9__c = a.cb4__Tag9__c,
                    cb4__Tag10__c = a.cb4__Tag10__c,
                    OwnerId = a.OwnerId
            );
            newAmounts.add(newA);
        }
        insert newAmounts;
    }

    /**
     * key - ext Id , value - app Id
     */
    private static Map<String, String> getSourceAppToNewAppMap() {
        Map<String, String> sourceAppToNewAppMap = new Map<String, String>();
        for (cb4__CBTag__c app : [SELECT Id, cb4__ExtId__c FROM cb4__CBTag__c WHERE cb4__Dimension__c = :budgetAppDimensionId AND cb4__ExtId__c != null]) sourceAppToNewAppMap.put(app.cb4__ExtId__c, app.Id);
        return sourceAppToNewAppMap;
    }

   /* private static Set<String> getNewAppsSourcesSet() {
        Set<String> r = new Set<String>();
        for (cb4__CBTag__c t : [SELECT cb4__ExtId__c FROM cb4__CBTag__c WHERE cb4__Dimension__c = :budgetAppDimensionId]) r.add(t.cb4__ExtId__c);
        return r;
    }*/


    private static Map<String, String> getMonthsMap(String sourceFYId, String targetFYId) {
        Map<String, String> r = new Map<String, String>();
        List<cb4__CBTag__c> sourcePeriods = [SELECT Id FROM cb4__CBTag__c WHERE cb4__Tag1__c = :sourceFYId AND cb4__Dimension__c = :periodDimensionId ORDER BY cb4__OrderNumber__c];
        List<cb4__CBTag__c> targetPeriods = [SELECT Id FROM cb4__CBTag__c WHERE cb4__Tag1__c = :targetFYId AND cb4__Dimension__c = :periodDimensionId ORDER BY cb4__OrderNumber__c];
        for (Integer i = 0; i < sourcePeriods.size(); i++) r.put(sourcePeriods[i].Id, targetPeriods[i].Id);
        return r;
    }

    private static Boolean alreadyDone(String targetType, String targetYear) {
        return [SELECT Id FROM cb4__CBTag__c WHERE cb4__Dimension__c = :budgetAppDimensionId AND cb4__Tag8Name__c = :targetType AND cb4__Tag3Name__c = :targetYear LIMIT 1].size() > 0;
    }


    /**
     * To prevent mapping errors, all external Id must be deleted after job finished
     */
    private static void removeOldExtIdFromApps() {
        List<cb4__CBTag__c> apps = [
                SELECT cb4__ExtId__c
                FROM cb4__CBTag__c
                WHERE cb4__DimensionName__c = 'Budget App'
                AND cb4__ExtId__c != null
        ];
        for (cb4__CBTag__c t : apps) t.cb4__ExtId__c = null;
        update apps;
    }


}