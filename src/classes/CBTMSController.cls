/**
 * Created by Alex JR on 8/31/2020.
 * The home component controller
 *
 * JOBS ORDER
 * 1. Delete old CB Reporting Balances (CBDeleteJob=>)
 * 1.1 Delete old FF RB (Budget and Forecast) in parallel
 * 2. FF Integration (CB_JOB_STEP_1=>)
 * 3. Posting Rules converts BA => Entries and CB Reporting Balances=> Entries (CB_JOB_STEP_2=>)
 * 4. CBEntryMapping (CB_JOB_STEP_3=>)
 * 5. Simple CBalanceRule calculation (CB_JOB_STEP_4=>)
 * 6. CBalanceGenerator => 3 CBalanceYTDandVariance (CB_JOB_STEP_5=>)
 * 7. FFBackwardIntegration (CB_JOB_STEP_6=>)
 * 8. Reporting Balances Mapping CBReportingBalancesProcessing
 *
 */

public with sharing class CBTMSController {

    private static Integer getPeriodNumByName(String year, String period){
        Integer periodNumber = 0;
        if(period != 'none') {
            for (cb4__CBTag__c p : [SELECT Id, Name FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Period' AND cb4__Tag1Name__c = :year ORDER BY cb4__Start__c ASC]) {
                periodNumber++;
                if (p.Name == period) break;
            }
        }
        return periodNumber;
    }

    @AuraEnabled
    public static String runMasterUpdateServer(String yearNumber) {
        Decimal currentStep = CBVariable.step;
        if (currentStep > 0) return 'Wait for the current update process to complete before starting a new one.';
        CB_JOB_START start = new CB_JOB_START();
        CBVariable.saveLastUpdateDate();
        return null;
    }

    @AuraEnabled
    public static void runCopyAppBudgetServer(String yearNumber, String sourceType, String sourceYear, String targetType, String targetYear) {
        if (targetYear == null || sourceYear == null || sourceType == null || targetType == null) return;
        CBBudgetAppCopier.runJob(sourceType, sourceYear, targetType, targetYear, null);
    }

    @AuraEnabled
    public static void runCitiesSyncServer(String yearNumber) {
        CBCityMapping.run();
    }

    @AuraEnabled
    public static void runBudgetDepartmentsSyncServer(String yearNumber) {
        CBTMSIntegration.syncBudgetDepartments();
    }


    @AuraEnabled
    public static void runReportingBalanceUpdateServer(String yearNumber) {
        Id jobId = Database.executeBatch(new CBReportingBalancesProcessing());
    }

    @AuraEnabled
    public static void runCBalanceGeneratorServer(String yearNumber) {
        CBalanceGenerator.runJobs(null);
    }

    @AuraEnabled
    public static void runForecastUpdateServer(String yearNumber, String forecastPeriod) {
        CBVariable.saveForecastLockPeriodsSettings(forecastPeriod);
        CBForecastGenerator.runJob(forecastPeriod, null);
    }

    @AuraEnabled
    public static void runUpdateBaseWithActualsServer(String baseYearNumber, String actualsPeriod) {
        CBForecastGenerator.runJob(baseYearNumber, actualsPeriod, null);
    }

    @AuraEnabled
    public static void runEntriesBDGUpdateServer(String yearNumber) {
        Id jobId = Database.executeBatch(new CBEntryMapping(null), 700);
    }

    @AuraEnabled
    public static void runCalculationRulesServer(String yearNumber){
        // Delete Old Calculated Amount batch
        String q = 'SELECT ' + cb4.CBUtils.getAllSObjectFields('cb4__CBTag__c', null) + ' WHERE cb4__DimensionName__c = \'Budget App\' AND cb4__Tag3Name__c = \'' + yearNumber + '\'';
        Map<Id, cb4__CBTag__c> budgetAppsMap = new Map<Id, cb4__CBTag__c>((List<cb4__CBTag__c>) Database.query(q));
        Set<Id> budgetAppIds = budgetAppsMap.keySet();
        CBRunCalculationRulesProcess runCalcRulesProcess = new CBRunCalculationRulesProcess(budgetAppIds);
        Set<String> idStrs = (Set<String>)JSON.deserialize(JSON.serialize(budgetAppIds), Set<String>.class);
        Map<String, String> sMap = new Map<String, String>{
                'custom' => ' cb4__DimensionName__c = \'Budget App Amount\'  AND cb4__Text5__c = \'calcRule\' AND cb4__Tag1__c IN ' + cb4.CBUtils.getFormattedINQuery(idStrs)
        };
        cb4.CBDeleteJob dj = new cb4.CBDeleteJob('cb4__CBTag__c', sMap, runCalcRulesProcess, 200);
        Id batchId = Database.executeBatch(dj, 2000);
    }

    @AuraEnabled
    public static String saveGlobalVariableServer(String fy, String emailRecipients) {
        CBVariable.saveCurrentFY(fy);
        CBVariable.saveEmailRecipients(emailRecipients);
        return 'ok';
    }

    @AuraEnabled
    public static Map<String, Object> getParametersSOServer() {
        Map<String, Object> r = new Map<String, Object>();
        r.put('years', CBService.getYearsSO());
        r.put('baseYears', CBService.getBaseYearsSO());
        r.put('fy', CBVariable.currentFY);
        r.put('emailRecipients', CBVariable.emailRecipients);
        List<cb4.CBSO> periods = CBService.getPeriodsSO();
        r.put('periods', periods);
        r.put('lockPeriods', periods);
        return r;
    }

    @AuraEnabled
    public static void sendTestEmailServer() {
        CBMasterUpdateScheduled.sendEmailToAdmin();
    }

    private static Map<String, cb4__CBTag__c> getCBAccountMap() {
        Map<String, cb4__CBTag__c> r = new Map<String, cb4__CBTag__c>();
        for (cb4__CBTag__c t : [
                SELECT cb4__ExtId__c,Id, cb4__Tag1__r.cb4__Tag1Name__c
                FROM cb4__CBTag__c
                WHERE cb4__DimensionName__c = 'Account'
                WITH SECURITY_ENFORCED
                LIMIT 50000
        ]) {
            r.put(t.cb4__ExtId__c, t);
        }
        return r;
    }

    @AuraEnabled
    public static Map<String, String> getFFvsCBStatsServer(){
        Map<String, cb4__CBTag__c> CBDimAccDepMap = getCBAccountMap();
        Integer cbrbNumber = 0, ffrbNumber = 0, upToDateItems = 0, rbWithoutBDG = 0, rbWithoutBRD = 0;
        Decimal cbrbTotal = 0, ffrbTotal = 0, amountsNotInCB = 0;
        Map<String, String> result = new Map<String, String>();
        Map<String, cb4__CBTag__c> extIdToCBRB = new Map<String, cb4__CBTag__c>();
        for(cb4__CBTag__c cbrb : [SELECT Id, cb4__Decimal1__c, cb4__ExtId__c, CreatedDate FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'CB Reporting Balance' AND cb4__Tag4Name__c = :CBVariable.currentFY]) {
            extIdToCBRB.put(cbrb.cb4__ExtId__c, cbrb);
            cbrbTotal += cbrb.cb4__Decimal1__c;
            cbRbNumber++;
        }
        for(c2g__ReportingBalance__c rb : [SELECT Id, c2g__DualValue__c, LastModifiedDate, c2g__GeneralLedgerAccount__c, BDG__c, Budget_Reporting_Department__c, Budget_Reporting_Department_2__c, Budget_Reporting_Department_3__c  FROM c2g__ReportingBalance__c WHERE
                                                    c2g__Period__r.c2g__Description__c = 'Trading Period' AND
                                                    c2g__OwnerCompany__c != null AND
                                                    c2g__GeneralLedgerAccount__c != null AND
                                                    c2g__DualValue__c != 0 AND
                                                    c2g__DualValue__c != null AND
                                                    c2g__GeneralLedgerAccount__r.c2g__Type__c = 'Profit and Loss' AND
                                                    c2g__YearNumber__c = :Integer.valueOf(CBVariable.currentFY) AND
                                                    c2g__Type__c = 'Actual']){
            Boolean FFRBisExpense = CBDimAccDepMap.get(rb.c2g__GeneralLedgerAccount__c).cb4__Tag1__r.cb4__Tag1Name__c == 'Expense';
            ffrbTotal = ffrbTotal + (FFRBisExpense ? rb.c2g__DualValue__c : -rb.c2g__DualValue__c);
            if(!extIdToCBRB.containsKey(rb.Id)){
                amountsNotInCB = amountsNotInCB + (FFRBisExpense ? rb.c2g__DualValue__c : -rb.c2g__DualValue__c);
            }else{
                if(rb.LastModifiedDate > extIdToCBRB.get(rb.Id).CreatedDate){
                    upToDateItems++;
                }
            }
            rbWithoutBDG = rbWithoutBDG + (rb.BDG__c == null ? 1 : 0);
            rbWithoutBRD = rbWithoutBRD + ((rb.Budget_Reporting_Department__c == null && rb.Budget_Reporting_Department_2__c == null && rb.Budget_Reporting_Department_3__c == null)? 1 : 0);
            ffrbNumber++;
        }

        result.put('ffrbNumber'            , String.valueOf(ffrbTotal.setScale(2).format()));
        result.put('cbrbNumber'            , String.valueOf(cbrbTotal.format()));
        result.put('ffcbAmountDifferences' , String.valueOf((ffrbTotal - cbrbTotal).setScale(2).format()));
        result.put('amountsnotincb'        , String.valueOf(amountsNotInCB.setScale(2).format()));
        result.put('ffrbWithoutLastUpdates', String.valueOf(upToDateItems.format()));
        result.put('rbWithoutBDG'          , String.valueOf(rbWithoutBDG.format()));
        result.put('rbWithoutBRD'          , String.valueOf(rbWithoutBRD.format()));
        return result;
    }

    @AuraEnabled
    public static List<cb4.CBSO> getPeriodsSOServer(String year){
        List<cb4.CBSO> periods = new List<cb4.CBSO>();
        for (cb4__CBTag__c a : [SELECT Name FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Period' AND cb4__Tag1Name__c = :year ORDER BY cb4__Start__c ASC]) periods.add(new cb4.CBSO(a.Name, a.Name));
        return periods;
    }

    @AuraEnabled
    public static String getLockedPeriodServer(String year){
        List<cb4__CBTag__c> fBudget = [SELECT Id, cb4__Decimal6__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Budget App' AND cb4__Tag3Name__c = :year AND cb4__Tag8Name__c = 'Forecast'  AND cb4__Decimal6__c != NULL];
        List<cb4__CBTag__c> periods = [SELECT Id, Name FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Period' AND cb4__Tag1Name__c = :year ORDER BY cb4__Start__c ASC];
        if(fBudget.isEmpty() || periods.isEmpty() || fBudget[0].cb4__Decimal6__c == 0) return 'none';
        return periods[Integer.valueOf(fBudget[0].cb4__Decimal6__c) - 1].Name;
    }

    @AuraEnabled
    public static void lockForecastBudgetsTillServer(String year, String period){
        Integer periodNumber = getPeriodNumByName(year, period);
        List<cb4__CBTag__c> upBudgets = new List<cb4__CBTag__c>();
        for(cb4__CBTag__c b : [SELECT Id, cb4__Decimal6__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Budget App' AND cb4__Tag3Name__c = :year AND cb4__Tag8Name__c = 'Forecast' AND (NOT Name LIKE '%Amort%')]){
            b.cb4__Decimal6__c = periodNumber;
            upBudgets.add(b);
        }
        update upBudgets;
    }

    @AuraEnabled
    public static String checkForecastUpdatePeriods(String year, String fcstPeriod){
        String lockedPeriod = getLockedPeriodServer(year);
        if(lockedPeriod != 'none' && getPeriodNumByName(year, fcstPeriod) <= getPeriodNumByName(year, lockedPeriod)) return 'false';
        return lockedPeriod;
    }

    @AuraEnabled
    public static String getFcstLockSettings(){
        Map<String, String> fcstSetts = (Map<String, String>) JSON.deserialize(CBVariable.fcstLockSettings, Map<String, String>.class);
        fcstSetts.put('currTime', String.valueOf(Datetime.now()));
        return JSON.serialize(fcstSetts);
    }

    @AuraEnabled
    public static String getProcessStepServer(){
        Integer minutesFromTheUpdate = CBVariable.getMinutesFromTheUpdateDate();
        if (minutesFromTheUpdate > 180) CBVariable.setStep(0);
        return String.valueOf(CBVariable.step);
    }

}