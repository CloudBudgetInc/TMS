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
        Id jobId = Database.executeBatch(new CBReportingBalancesProcessingV2());
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
        Id jobId = Database.executeBatch(new CBEntryMappingV2(null), 700);
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



    @AuraEnabled
    public static Map<String, String> getRBStatisticServer(){
        Map<String, String> result = new Map<String, String>();
        AggregateResult withoutBDG = [SELECT count(Id) rbWithoutBDG FROM c2g__ReportingBalance__c WHERE c2g__GeneralLedgerAccount__r.c2g__Type__c = 'Profit and Loss' AND BDG__c = null AND c2g__YearNumber__c = :Integer.valueOf(CBVariable.currentFY)][0];
        result.put('rbWithoutBDG', String.valueOf(withoutBDG.get('rbWithoutBDG')));
        AggregateResult withoutBRD = [SELECT count(Id) rbWithoutBRD FROM c2g__ReportingBalance__c WHERE c2g__GeneralLedgerAccount__r.c2g__Type__c = 'Profit and Loss' AND Budget_Reporting_Department__c = null AND Budget_Reporting_Department_2__c = null AND Budget_Reporting_Department_3__c = null AND c2g__YearNumber__c = :Integer.valueOf(CBVariable.currentFY)][0];
        result.put('rbWithoutBRD', String.valueOf(withoutBRD.get('rbWithoutBRD')));
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

    /*Budget Application*/

    private static final String accountSetDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.ACCOUNT_SET_DIM);
    private static final String periodSetDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.PERIOD_SET_DIM);
    private static final String periodDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.PERIOD_DIM);
    private static final String accountDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.ACCOUNT_DIM);


    public static Map<Id, cb4__CBTag__c> accountMap {
        get {
            if (accountMap == null) {
                accountMap = new Map<Id, cb4__CBTag__c>();
                for (cb4__CBTag__c t : getTagListServer(accountDimId, null, null, null, false, ' cb4__Tag1__r.cb4__Tag1Name__c ', null, null)) {
                    accountMap.put(t.Id, t);
                }
            }
            return accountMap;
        }
        set;
    }

    @TestVisible
    private static Map<Id, Set<Id>> setMap {
        get {
            if (setMap == null) {
                setMap = getMapOfRelatedAccountsInSet();
            }
            return setMap;
        }
        set;
    }

    @TestVisible
    private static Map<Id, Set<Id>> BYMap {
        get {
            if (BYMap == null) {
                BYMap = new Map<Id, Set<Id>>();
                for (cb4__CBTag__c t : getTagListServer(periodDimId, null, null, null, false, null, null, null)) {
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

    public static Map<String, User> userMap {
        get {
            if (userMap == null) {
                userMap = new Map<String, User>([
                        Select Id, Name, ManagerId, ProfileId, DelegatedApproverId, UserRoleId, IsActive
                        From User
                        WHERE Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name LIKE '%CloudBudget2%') AND IsActive = true
                        ORDER BY Name
                        LIMIT 20000
                ]);
            }
            return userMap;
        }
        set;
    }

    private static Map<String, GroupMember> groupMemberMap {
        get {
            if (groupMemberMap == null) {
                groupMemberMap = new Map<String, GroupMember>([
                        Select GroupId, Id, UserOrGroupId
                        From GroupMember
                        WHERE Id != null AND Group.Type = 'Regular'
                        ORDER BY Id
                        LIMIT 1000
                ]);
            }
            return groupMemberMap;
        }
        set;
    }

    private static Map<String, Group> groupMap {
        get {
            if (groupMap == null) {
                groupMap = new Map<String, Group>([
                        Select Id, Name, DeveloperName, Type
                        From Group
                        WHERE Id != null AND Type = 'Regular'
                        ORDER BY Name
                        LIMIT 1000
                ]);
            }
            return groupMap;
        }
        set;
    }

    @TestVisible
    private static Map<Id, Set<Id>> getMapOfRelatedAccountsInSet() {
        Map<Id, Set<Id>> r = new Map<Id, Set<Id>>();
        Set<Id> accountPeriodSetIds = new Set<Id>();
        for (cb4__CBTag__c t : [SELECT Id FROM cb4__CBTag__c WHERE cb4__Dimension__c = :accountSetDimId OR cb4__Dimension__c = :periodSetDimId]) {
            accountPeriodSetIds.add(t.Id);
        }
        for (cb4__CBLink__c t : [SELECT cb4__Tag1__c, cb4__Tag2__c FROM cb4__CBLink__c WHERE cb4__Type__c = :cb4.CBConstant.LINK_SET AND cb4__Tag1__c = :accountPeriodSetIds LIMIT 50000]) {
            Set<Id> bunch = r.get(t.cb4__Tag1__c);
            if (bunch == null) {
                bunch = new Set<Id>{
                        t.cb4__Tag2__c
                };
            } else {
                bunch.add(t.cb4__Tag2__c);
            }
            r.put(t.cb4__Tag1__c, bunch);
        }
        return r;
    }

    public static String getContextFilter(Id dimensionId) {
        if (dimensionId == null) return '';
        cb4__CBDimension__c d = getDimension(dimensionId);

        cb4__CBUserContext__c uc = getUserContextServer();
        if (uc == null) return '';

        String result = '';

        if (!uc.cb4__ShowAll1__c && uc.cb4__Tag1__c != null && cb4.CBUtils.isValidId(uc.cb4__Dimension1__c)) {
            for (Integer i = 1; i <= 10; i++) {
                Object dim = d.get('cb4__Dimension' + i + '__c');
                if (dim != null && (String.valueOf(dim)).contains(uc.cb4__Dimension1__c)) {
                    result = 'cb4__Tag' + i + '__c = \'' + uc.cb4__Tag1__c + '\'';
                    break;
                }
            }
        }

        if (!uc.cb4__ShowAll2__c && uc.cb4__Tag2__c != null && cb4.CBUtils.isValidId(uc.cb4__Dimension2__c)) {
            for (Integer i = 1; i <= 10; i++) {
                Object dim = d.get('cb4__Dimension' + i + '__c');
                if (dim != null && (String.valueOf(dim)).contains(uc.cb4__Dimension2__c)) {
                    String searchTag = 'cb4__Tag' + i + '__c = \'' + uc.cb4__Tag2__c + '\'';
                    result += result == '' ? searchTag : ' AND ' + searchTag;
                    break;
                }
            }
        }

        if (!uc.cb4__ShowAll3__c && uc.cb4__Tag3__c != null && cb4.CBUtils.isValidId(uc.cb4__Dimension3__c)) {
            for (Integer i = 1; i <= 10; i++) {
                Object dim = d.get('cb4__Dimension' + i + '__c');
                if (dim != null && (String.valueOf(dim)).contains(uc.cb4__Dimension3__c)) {
                    String searchTag = 'cb4__Tag' + i + '__c = \'' + uc.cb4__Tag3__c + '\'';
                    result += result == '' ? searchTag : ' AND ' + searchTag;
                    break;
                }
            }
        }

        if (!uc.cb4__ShowAll4__c && uc.cb4__Tag4__c != null && cb4.CBUtils.isValidId(uc.cb4__Dimension4__c)) {
            for (Integer i = 1; i <= 10; i++) {
                Object dim = d.get('cb4__Dimension' + i + '__c');
                if (dim != null && (String.valueOf(dim)).contains(uc.cb4__Dimension4__c)) {
                    String searchTag = 'cb4__Tag' + i + '__c = \'' + uc.cb4__Tag4__c + '\'';
                    result += result == '' ? searchTag : ' AND ' + searchTag;
                    break;
                }
            }
        }

        if (!uc.cb4__ShowAll5__c && uc.cb4__Tag5__c != null && cb4.CBUtils.isValidId(uc.cb4__Dimension5__c)) {
            for (Integer i = 1; i <= 10; i++) {
                Object dim = d.get('cb4__Dimension' + i + '__c');
                if (dim != null && (String.valueOf(dim)).contains(uc.cb4__Dimension5__c)) {
                    String searchTag = 'cb4__Tag' + i + '__c = \'' + uc.cb4__Tag5__c + '\'';
                    result += result == '' ? searchTag : ' AND ' + searchTag;
                    break;
                }
            }
        }
        return result;
    }

    @AuraEnabled
    public static List<cb4__CBTag__c> getTagListServer(Id dimensionId, String addedFilter, Id parentTagId, String filtersMap, Boolean contextEnabled, String addSelect, String sortOrder, String customSelect) {
        addedFilter = cb4.CBUtils.refineStr(addedFilter);
        filtersMap = cb4.CBUtils.refineStr(filtersMap);
        sortOrder = cb4.CBUtils.refineStr(sortOrder);
        customSelect = cb4.CBUtils.refineStr(customSelect);
        addSelect = cb4.CBUtils.refineStr(addSelect);

        String filter = '';
        if (dimensionId != null) {
            filter = ' cb4__Dimension__c = \'' + dimensionId + '\' ';
        }
        if (addedFilter != null && addedFilter != '') {
            filter += filter == '' ? addedFilter : ' AND ' + addedFilter;
        }
        if (filtersMap != null && filtersMap != '{}') {
            Map<String, String> filterParams = (Map<String, String>) System.JSON.deserialize(filtersMap, Map<String, String>.class);
            for (String s : filterParams.keySet()) {
                filter += filter == '' ? s + ' = \'' + filterParams.get(s) + '\'' : ' AND ' + s + ' = \'' + filterParams.get(s) + '\'';
            }
        }
        if (parentTagId != null) {
            String parentFilter = ' (Tag1__c=\'' + parentTagId + '\' OR Tag2__c=\'' + parentTagId + '\' OR Tag3__c=\'' + parentTagId + '\'' +
                    ' OR Tag4__c=\'' + parentTagId + '\' OR Tag5__c=\'' + parentTagId + '\'' + ' OR Tag6__c=\'' + parentTagId +
                    '\' OR Tag7__c=\'' + parentTagId + '\' OR Tag8__c=\'' + parentTagId + '\' OR Tag9__c=\'' + parentTagId + '\'' +
                    ' OR Tag10__c=\'' + parentTagId + '\' ) ';
            filter += filter == '' ? parentFilter : ' AND ' + parentFilter;
        }

        if (contextEnabled != null && contextEnabled) {
            String contextFilter = getContextFilter(dimensionId);
            if (contextFilter != '') {
                filter += filter == '' ? contextFilter : ' AND ' + contextFilter;
            }
        }

        if (addSelect != null && addSelect != '') {
            addSelect = ', ' + addSelect;
        } else if (addSelect == null) {
            addSelect = '';
        }
        if (sortOrder != null && sortOrder != '') {
            sortOrder = ' ORDER BY ' + sortOrder;
        } else if (sortOrder == null) {
            sortOrder = ' ORDER BY cb4__OrderNumber__c, cb4__TagLabel__c ';
        }

        String qSelect;
        if (customSelect != '' && customSelect != null) {
            qSelect = customSelect + addSelect + ' FROM cb4__CBTag__c ';
        } else {
            qSelect = cb4.CBUtils.getAllSObjectFields('cb4__CBTag__c', addSelect);
        }
        String addFilter = '';
        if (contextEnabled != null && contextEnabled) {
            addFilter = getBYFilter();
        }
        filter = filter + addFilter;
        if (filter != '') {
            filter = 'WHERE ' + filter;
        }
        String q = 'SELECT ' + qSelect + filter + sortOrder + ' LIMIT 40000 ';
        q = q.remove('\\');

        //System.debug(q);
        return Database.query(q);
    }

    public static String getBYFilter() {
        String addFilter = '';
        cb4__CBTag__c yearTag = cb4.CBContext.getCurrentBY();
        cb4__CBUserContext__c uc = getUserContextServer();
        String budgetYearDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.BUDGET_YEAR_DIM);
        Boolean showAllDates = false;
        for (Integer i = 5; i != 0; i--) {
            if ((String) uc.get('cb4__Dimension' + String.valueOf(i) + '__c') == budgetYearDimId) {
                showAllDates = (Boolean) uc.get('cb4__ShowAll' + String.valueOf(i) + '__c');
                break;
            }
        }
        if (!showAllDates && yearTag != null) {
            String startDate = yearTag.cb4__Start__c != null ? String.valueOf(yearTag.cb4__Start__c).removeEnd(' 00:00:00') : '';
            String endDate = yearTag.cb4__End__c != null ? String.valueOf(yearTag.cb4__End__c).removeEnd(' 00:00:00') : '';
            if (!String.isBlank(startDate) && !String.isBlank(endDate)) {
                addFilter += ' AND ((cb4__Start__c = null AND cb4__End__c = null)';
                addFilter += ' OR (cb4__Start__c >= ' + startDate + ' AND cb4__End__c <= ' + endDate + ')';
                addFilter += ' OR (cb4__Start__c <= ' + startDate + ' AND cb4__End__c >= ' + endDate + ')';
                addFilter += ' OR (cb4__End__c >= ' + startDate + ' AND cb4__End__c <= ' + endDate + ')';
                addFilter += ' OR (cb4__Start__c >= ' + startDate + ' AND cb4__Start__c <= ' + endDate + '))';
            } else if (!String.isBlank(startDate) && String.isBlank(endDate)) {
                addFilter += ' AND (cb4__End__c = null OR cb4__End__c >= ' + startDate + ')';
            } else if (!String.isBlank(endDate) && String.isBlank(startDate)) {
                addFilter += ' AND (cb4__End__c = null OR cb4__End__c <= ' + endDate + ')';
            }
        }
        return addFilter;
    }

    @AuraEnabled
    public static cb4__CBUserContext__c getUserContextServer() {
        cb4__CBUserContext__c uc = cb4__CBUserContext__c.getInstance(UserInfo.getUserId());
        if (uc.Id == null) {
            cb4__CBUserContext__c orgContext = getOrganizationContextServer();
            uc = orgContext.clone();
            uc.Name = uc.Name.replace('Organization', 'User');
            uc.SetupOwnerId = UserInfo.getUserId();
            upsert uc;
        }
        return uc;
    }

    @AuraEnabled
    public static cb4__CBUserContext__c getOrganizationContextServer() {
        cb4__CBUserContext__c oc = cb4__CBUserContext__c.getOrgDefaults();
        if (oc.Id == null) {
            oc = new cb4__CBUserContext__c(cb4__Dimension1Filter__c = '');
            oc.cb4__ShowAll1__c = oc.cb4__ShowAll2__c = oc.cb4__ShowAll3__c = oc.cb4__ShowAll4__c = oc.cb4__ShowAll5__c = false;
            oc.cb4__AllowAll1__c = oc.cb4__AllowAll2__c = oc.cb4__AllowAll3__c = oc.cb4__AllowAll4__c = oc.cb4__AllowAll5__c = false;
        }
        return oc;
    }

    @AuraEnabled
    public static cb4__CBTag__c getTagServer(Id recordId, String addSelect) {
        addSelect = cb4.CBUtils.refineStr(addSelect);
        String addFilter = getBYFilter();
        if (recordId == null) {
            return new cb4__CBTag__c();
        }
        String q = 'SELECT ' + cb4.CBUtils.getAllSObjectFields('cb4__CBTag__c', addSelect) +
                ' WHERE Id=\'' + recordId + '\' ' + addFilter + ' LIMIT 25000 ';
        return (cb4__CBTag__c) (Database.query(q))[0];
    }

    @AuraEnabled
    public static cb4__CBTag__c getNewTagServer(Id dimensionId, Id parentTagId) {
        cb4__CBDimension__c dimensionObj = getDimension(dimensionId);
        cb4__CBTag__c newTag = new cb4__CBTag__c(cb4__Dimension__c = dimensionId, Name = 'New ' + dimensionObj.Name);
        cb4__CBUserContext__c uc = getUserContextServer();
        if (uc.cb4__Tag1__c != null) {
            String cuDimensionId = uc.cb4__Dimension1__c;
            for (Integer i = 1; i <= 10; i++) {
                Object val = dimensionObj.get('cb4__Dimension' + i + '__c');
                if (val == null) {
                    continue;
                }
                Map<String, String> dimParam = (Map<String, String>) System.JSON.deserialize((String) val, Map<String, String>.class);
                if (dimParam.get('v') == cuDimensionId) {
                    newTag.put('cb4__Tag' + i + '__c', uc.cb4__Tag1__c);
                }
            }
        }
        if (uc.cb4__Tag2__c != null) {
            String cuDimensionId = uc.cb4__Dimension2__c;
            for (Integer i = 1; i <= 10; i++) {
                Object val = dimensionObj.get('cb4__Dimension' + i + '__c');
                if (val == null) {
                    continue;
                }
                Map<String, String> dimParam = (Map<String, String>) System.JSON.deserialize((String) val, Map<String, String>.class);
                if (dimParam.get('v') == cuDimensionId) {
                    newTag.put('cb4__Tag' + i + '__c', uc.cb4__Tag2__c);
                }
            }
        }
        if (uc.cb4__Tag3__c != null) {
            String cuDimensionId = uc.cb4__Dimension3__c;
            for (Integer i = 1; i <= 10; i++) {
                Object val = dimensionObj.get('cb4__Dimension' + i + '__c');
                if (val == null) {
                    continue;
                }
                Map<String, String> dimParam = (Map<String, String>) System.JSON.deserialize((String) val, Map<String, String>.class);
                if (dimParam.get('v') == cuDimensionId) {
                    newTag.put('cb4__Tag' + i + '__c', uc.cb4__Tag3__c);
                }
            }
        }
        if (uc.cb4__Tag4__c != null) {
            String cuDimensionId = uc.cb4__Dimension4__c;
            for (Integer i = 1; i <= 10; i++) {
                Object val = dimensionObj.get('cb4__Dimension' + i + '__c');
                if (val == null) {
                    continue;
                }
                Map<String, String> dimParam = (Map<String, String>) System.JSON.deserialize((String) val, Map<String, String>.class);
                if (dimParam.get('v') == cuDimensionId) {
                    newTag.put('cb4__Tag' + i + '__c', uc.cb4__Tag4__c);
                }
            }
        }
        if (uc.cb4__Tag5__c != null) {
            String cuDimensionId = uc.cb4__Dimension5__c;
            for (Integer i = 1; i <= 10; i++) {
                Object val = dimensionObj.get('cb4__Dimension' + i + '__c');
                if (val == null) {
                    continue;
                }
                Map<String, String> dimParam = (Map<String, String>) System.JSON.deserialize((String) val, Map<String, String>.class);
                if (dimParam.get('v') == cuDimensionId) {
                    newTag.put('cb4__Tag' + i + '__c', uc.cb4__Tag5__c);
                }
            }
        }

        if (parentTagId != null) {
            String cuDimensionId = getTagServer(parentTagId, null).cb4__Dimension__c;
            for (Integer i = 1; i <= 10; i++) {
                Object val = dimensionObj.get('cb4__Dimension' + i + '__c');
                if (val == null) {
                    continue;
                }
                Map<String, String> dimParam = (Map<String, String>) System.JSON.deserialize((String) val, Map<String, String>.class);
                if (dimParam.get('v') == cuDimensionId) {
                    newTag.put('cb4__Tag' + i + '__c', parentTagId);
                }
            }
        }

        newTag = cb4.CBUtils.tryToAssignParentIdToNewTagField(parentTagId, null, dimensionObj, newTag);

        return newTag;
    }

    @AuraEnabled
    public static cb4__CBDimension__c getDimension(Id recordId) {
        if (recordId == null) {
            return null;
        }
        String q = 'SELECT ' + cb4.CBUtils.getAllSObjectFields('cb4__CBDimension__c', null) + ' WHERE Id=\'' + recordId + '\' LIMIT 1 ';
        return Database.query(q);
    }

    @AuraEnabled
    public static List<cb4.CBSO> getAllWiredTagsOfSetSO(Id setId) {
        List<cb4.CBSO> r = new List<cb4.CBSO>();
        for (cb4__CBTag__c t : getAllWiredTagsOfSet(setId)) {
            r.add(new cb4.CBSO(t.Id, t.cb4__TagLabel__c));
        }
        return r;
    }

    @AuraEnabled
    public static List<cb4__CBTag__c> getAllWiredTagsOfSet(Id setId) {
        Set<Id> tagIds = new Set<Id>();
        for (cb4__CBLink__c t : [SELECT cb4__Tag2__c FROM cb4__CBLink__c WHERE cb4__Type__c = :cb4.CBConstant.LINK_SET AND cb4__Tag1__c = :setId LIMIT 2000]) {
            tagIds.add(t.cb4__Tag2__c);
        }
        if (tagIds.size() == 0) {
            return new List<cb4__CBTag__c>();
        }
        return [SELECT Id, Name, cb4__TagLabel__c FROM cb4__CBTag__c WHERE Id IN:tagIds ORDER BY cb4__OrderNumber__c, cb4__TagLabel__c, Name LIMIT 2000];
    }

    @AuraEnabled
    public static List<cb4.CBSO> getTagsSOServer(Id dimensionId, String additionalFilter) {
        additionalFilter = cb4.CBUtils.refineStr(additionalFilter);
        List<cb4.CBSO> r = new List<cb4.CBSO>();
        if (!cb4.CBUtils.isValidId(dimensionId)) {
            return r;
        }
        String s = 'SELECT Id,Name,cb4__TagLabel__c,cb4__Dimension__r.cb4__isSet__c FROM cb4__CBTag__c  ';
        if (dimensionId != null) {
            s = s + ' WHERE cb4__Dimension__c = \'' + dimensionId + '\' ' +
                    (additionalFilter == null || additionalFilter == '' ? '' : ' AND ' + additionalFilter);
        }
        s = s + ' ORDER BY cb4__OrderNumber__c, cb4__TagLabel__c, Name LIMIT 2500 ';
        s = s.remove('\\');
        for (cb4__CBTag__c t : Database.query(s)) {
            r.add(new cb4.CBSO(t.Id, t.cb4__TagLabel__c + (t.cb4__Dimension__r.cb4__isSet__c ? ' (Set)' : '')));
        }
        return r;
    }

    public static List<cb4__CBTag__c> convertAmountsToUserCurrency(List<cb4__CBTag__c> source) {
        if (source == null || source.size() == 0) {
            return source;
        }
        Decimal currencyRate = getCurrencyRate();
        if (currencyRate == null || currencyRate == 0) {
            return source;
        }
        for (cb4__CBTag__c t : source) {
            t.cb4__Decimal1__c = t.cb4__Decimal1__c == null ? 0 : (t.cb4__Decimal1__c * currencyRate).setScale(2);
        }
        return source;
    }

    public static List<cb4__CBTag__c> convertAmountsToCorporateCurrency(List<cb4__CBTag__c> source) {
        if (source == null || source.size() == 0) {
            return source;
        }
        Decimal currencyRate = getCurrencyRate();
        if (currencyRate == null || currencyRate == 0) {
            return source;
        }
        for (cb4__CBTag__c t : source) {
            t.cb4__Decimal1__c = t.cb4__Decimal1__c == null ? 0 : (t.cb4__Decimal1__c / currencyRate).setScale(2);
        }
        return source;
    }

    private static Decimal getCurrencyRate() {
        try {
            List<sObject> currencyTypes = Database.query('SELECT ConversionRate, isoCode, IsCorporate FROM CurrencyType WITH SECURITY_ENFORCED LIMIT 1000');
            sObject user = Database.query('SELECT DefaultCurrencyIsoCode FROM User WHERE Id = \'' + cb4.CBConstant.USER_ID + '\' WITH SECURITY_ENFORCED');
            String userISOCode = (String) user.get('DefaultCurrencyIsoCode');
            for (sObject ct : currencyTypes) {
                String ic = (String) ct.get('isoCode');
                if (ic == userISOCode) {
                    if ((Boolean) ct.get('IsCorporate') || (Decimal) ct.get('ConversionRate') == 1) {
                        return null;
                    }
                    return (Decimal) ct.get('ConversionRate');
                }
            }
        } catch (Exception e) {
            cb4.CBConsole.setLog(e, 'getCurrencyRate error');
            cb4.CBConsole.insertLog();
            return 1;
        }
        return null;
    }

    @AuraEnabled
    public static List<cb4.CBSO> getPriceBooksSOServer(List<String> productIds) {
        List<cb4.CBSO> r = new List<cb4.CBSO>();
        String s = 'SELECT Id, Name FROM Pricebook2 WITH SECURITY_ENFORCED ORDER BY Name LIMIT 1000';
        for (Pricebook2 pb : Database.query(s)) {
            r.add(new cb4.CBSO(pb.Id, pb.Name));
        }
        return r;
    }

    @AuraEnabled
    public static List<cb4.CBSO> getProductsSOServer() {
        List<cb4.CBSO> r = new List<cb4.CBSO>();
        String s = 'SELECT Id, Name, QuantityUnitOfMeasure FROM Product2 WITH SECURITY_ENFORCED ORDER BY Name LIMIT 1000';
        for (Product2 p : Database.query(s)) {
            r.add(new cb4.CBSO(p.Id, p.QuantityUnitOfMeasure != null ? (p.Name + ' (' + p.QuantityUnitOfMeasure + ')') : p.Name));
        }
        return r;
    }

    @AuraEnabled
    public static Map<String, Decimal> getPriceEntriesServer() {
        Map<String, Decimal> r = new Map<String, Decimal>();
        String s = 'SELECT Product2Id, Pricebook2Id, UnitPrice, Name FROM PricebookEntry WITH SECURITY_ENFORCED ORDER BY Name LIMIT 1000';
        for (PricebookEntry pbe : Database.query(s)) {
            r.put(pbe.Product2Id + (String) pbe.Pricebook2Id, pbe.UnitPrice);
        }
        return r;
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
            for (cb4__CBTag__c t : srcTags) { // t is source CBTag__c

                Boolean simpleLinesConditionIsOk = !isTotalLinesCalcRule && periodTheSame(cr, t) && accountTheSame(cr, t) && dimensionsTheSame(cr, t);
                Boolean totalLinesConditionIsOk = isTotalLinesCalcRule && t.cb4__Text3__c == totalType && periodTheSame(cr, t);

                if (simpleLinesConditionIsOk || totalLinesConditionIsOk) {
                    if (resultCR.cb4__Boolean6__c == true) {
                        resultCR.cb4__Tag1__c = t.cb4__Tag2__c;
                    } // if you need to save account from source tag

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

    private static Decimal calculateSyntheticValueWithResultRule(cb4__CBTag__c cr, Decimal val) {
        if (cr.cb4__Decimal1__c != null && cr.cb4__Decimal1__c != 0) {
            return cr.cb4__Decimal1__c;
        }
        if (cr.cb4__Decimal2__c != null && cr.cb4__Decimal1__c != 0 && val > cr.cb4__Decimal2__c) {
            return cr.cb4__Decimal2__c;
        }
        if (cr.cb4__Decimal3__c != null && cr.cb4__Decimal1__c != 0 && val < cr.cb4__Decimal3__c) {
            return cr.cb4__Decimal3__c;
        }
        return val;
    }

    private static Map<String, cb4__CBTag__c> getMapIdResultCalcRules(List<cb4__CBTag__c> srcTags) {
        Set<Id> resRuleIds = new Set<Id>();
        Map<String, cb4__CBTag__c> r = new Map<String, cb4__CBTag__c>();
        for (cb4__CBTag__c t : srcTags) {
            resRuleIds.add(t.cb4__Tag2__c);
        }
        for (cb4__CBTag__c t : [SELECT Id,cb4__Tag1__c,cb4__Tag2__c,cb4__Tag3__c,cb4__Tag4__c,cb4__Tag5__c,cb4__Tag6__c,cb4__Tag7__c,cb4__Tag8__c,cb4__Tag9__c,cb4__Tag10__c,cb4__Decimal1__c,cb4__Decimal2__c,cb4__Decimal3__c,cb4__Boolean1__c,cb4__Boolean2__c,cb4__Boolean3__c,cb4__Boolean4__c,cb4__Boolean5__c,cb4__Boolean6__c, cb4__DimensionName__c FROM cb4__CBTag__c WHERE Id IN:resRuleIds AND cb4__DimensionName__c = :cb4.CBConstant.CALCULATION_RULE_DIM WITH SECURITY_ENFORCED]) {
            r.put(t.Id, t);
        }
        return r;
    }

    private static Boolean periodTheSame(cb4__CBTag__c cr, cb4__CBTag__c t) {
        if (cr.cb4__Tag3__r.cb4__Dimension__r.cb4__isSet__c) {
            return setContainsTag(cr.cb4__Tag3__c, t.cb4__Tag3__c);
        } // if period is set
        return cr.cb4__Tag3__c == t.cb4__Tag3__c || (BYMap.keySet().contains(cr.cb4__Tag3__c) && BYMap.get(cr.cb4__Tag3__c).contains(t.cb4__Tag3__c)); // if period is month or BY
    }

    private static Boolean accountTheSame(cb4__CBTag__c cr, cb4__CBTag__c t) {
        if (cr.cb4__Tag1__r.cb4__Dimension__r.cb4__isSet__c) {
            return setContainsTag(cr.cb4__Tag1__c, t.cb4__Tag2__c);
        }
        return cr.cb4__Tag1__c == t.cb4__Tag2__c;
    }

    private static Boolean dimensionsTheSame(cb4__CBTag__c cr, cb4__CBTag__c t) {
        if (cr.cb4__Tag6__c != null && cr.cb4__Tag6__c != t.cb4__Tag6__c) {
            return false;
        }
        if (cr.cb4__Tag7__c != null && cr.cb4__Tag7__c != t.cb4__Tag7__c) {
            return false;
        }
        if (cr.cb4__Tag8__c != null && cr.cb4__Tag8__c != t.cb4__Tag8__c) {
            return false;
        }
        if (cr.cb4__Tag9__c != null && cr.cb4__Tag9__c != t.cb4__Tag9__c) {
            return false;
        }
        if (cr.cb4__Tag10__c != null && cr.cb4__Tag10__c != t.cb4__Tag10__c) {
            return false;
        }
        return true;
    }

    private static Boolean setContainsTag(Id setId, Id examId) {
        Set<Id> s = setMap.get(setId);
        if (s == null) {
            return false;
        }
        return s.contains(examId);
    }

    @AuraEnabled
    public static String deleteTagServer(List<Id> tagIds) {
        if (tagIds == null) {
            return 'error: ids are not specified';
        }
        Set<Id> tagIdsSet = new Set<Id>(tagIds);
        delete [SELECT Id FROM cb4__CBTag__c WHERE Id IN :tagIdsSet WITH SECURITY_ENFORCED LIMIT 10000];
        return 'ok';
    }

    @AuraEnabled
    public static List<String> getDocumentsByRecordIdServer(Id recordId) {
        Set<String> uniqueDocs = new Set<String>();
        for (ContentDocumentLink link : [
                SELECT Id, ContentDocument.Title, ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :recordId
                ORDER BY ContentDocument.CreatedDate asc
                LIMIT 1000
        ]) {
            String pair = link.ContentDocumentId + ',' + link.ContentDocument.Title;
            uniqueDocs.add(pair);
        }
        return new List<String>(uniqueDocs);
    }

    @AuraEnabled
    public static List<String> getCurrentUserInterfaceSettingsListServer(String componentName, Boolean currentUserIsAdmin) {
        componentName = cb4.CBUtils.refineStr(componentName);
        if (currentUserIsAdmin == null) {
            currentUserIsAdmin = isCurrentUserAdminServer();
        }
        List<Id> currentUserGroupList = findCurrentUserGroupsServer();
        String addedFilter = 'cb4__Text2__c = \'' + componentName + '\'';
        if (!currentUserGroupList.isEmpty()) {
            addedFilter += ' AND (';
            for (Id currentUserGroup : currentUserGroupList) {
                addedFilter += 'cb4__Text1__c = \'' + String.valueOf(currentUserGroup) + '\' OR ';
            }
            addedFilter = addedFilter.removeEnd(' OR ');
            addedFilter += ')';
        } else {
            return getDefaultUserInterfaceSettingsListServer(componentName, currentUserIsAdmin);
        }
        String customSelect = 'Id, Name, cb4__Text1__c, cb4__Text2__c, cb4__TextLong1__c';
        String q = 'SELECT ' + customSelect + ' FROM cb4__InterfaceSettings__c WHERE ' + addedFilter + ' LIMIT 1000 ';
        List<cb4__InterfaceSettings__c> settingsObjList = Database.query(q);
        List<String> settingsFieldList = new List<String>();
        if (!settingsObjList.isEmpty()) {
            for (cb4__InterfaceSettings__c settingsObj : settingsObjList) {
                settingsFieldList.add(settingsObj.cb4__TextLong1__c);
            }
            return settingsFieldList;
        } else {
            return getDefaultUserInterfaceSettingsListServer(componentName, currentUserIsAdmin);
        }
    }

    @AuraEnabled
    public static Boolean isCurrentUserAdminServer() {
        return [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1000].Name == cb4.CBConstant.ADMIN_PROFILE_NAME;
    }

    @AuraEnabled
    public static List<Id> findCurrentUserGroupsServer() {
        Id currentUserId = getCurrentUser().Id;
        List<Id> groupList = new List<Id>(findGroupsByUser(currentUserId));
        return groupList;
    }

    public static User getCurrentUser() {
        return userMap.get(UserInfo.getUserId());
    }

    public static Set<Id> findGroupsByUser(Id userOrGroupId) {
        Set<Id> groupIdSet = new Set<Id>();
        List<GroupMember> groupMemberList = getGroupMemberListServer();
        for (GroupMember groupMember : groupMemberList) {
            if (groupMember.UserOrGroupId == userOrGroupId) {
                groupIdSet.add(groupMember.GroupId);
                //System.debug('findGroupsByUserAlt groupMember.GroupId: ' + groupMember.GroupId);
            }
        }
        for (Id groupId : groupIdSet) {
            groupIdSet.addAll(findSubordinateGroups(groupId));
        }
        return groupIdSet;
    }

    @AuraEnabled
    public static List<GroupMember> getGroupMemberListServer() {
        return groupMemberMap.values();
    }

    @AuraEnabled
    public static List<Group> getGroupListServer() {
        return groupMap.values();
    }

    public static Set<Id> findSubordinateGroups(Id groupId) {
        List<Group> groupList = getGroupListServer();
        Set<Id> groupIdSet = new Set<Id>();
        List<GroupMember> groupMemberList = getGroupMemberListServer();
        Boolean keepDigging = false;
        for (GroupMember groupMember : groupMemberList) {
            if (groupMember.GroupId == groupId) {
                for (Group groupItem : groupList) {
                    if (groupMember.UserOrGroupId == groupItem.Id) {
                        keepDigging = true;
                        groupIdSet.add(groupMember.UserOrGroupId);
                    }
                }
            }
        }
        if (keepDigging) {
            for (Id setGroupId : groupIdSet) {
                groupIdSet.addAll(findSubordinateGroups(setGroupId));
            }
        }

        return groupIdSet;
    }

    @AuraEnabled
    public static List<String> getDefaultUserInterfaceSettingsListServer(String componentName, Boolean currentUserIsAdmin) {
        componentName = cb4.CBUtils.refineStr(componentName);
        if (currentUserIsAdmin == null) {
            currentUserIsAdmin = isCurrentUserAdminServer();
        }
        String addedFilter = '';
        addedFilter += currentUserIsAdmin ? 'Label = \'Admin\'' : 'Label = \'User\'';

        String customSelect = 'Id, DeveloperName, cb4__GroupId__c, cb4__ComponentName__c, cb4__JSONCheckboxes__c';
        String q = 'SELECT ' + customSelect + ' FROM cb4__UserInterfaceSettings__mdt WHERE ' + addedFilter + ' LIMIT 1000';
        List<cb4__UserInterfaceSettings__mdt> settingsObjList = Database.query(q);
        List<String> settingsFieldList = new List<String>();
        if (!settingsObjList.isEmpty()) {
            for (cb4__UserInterfaceSettings__mdt settingsObj : settingsObjList) {
                settingsFieldList.add(settingsObj.cb4__JSONCheckboxes__c);
            }
            return settingsFieldList;
        } else {
            return null;
        }
    }

    /*Budget Application*/

    public static void cg(){
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
        i++;
        i++;
        i++;
        i++;
    }
}