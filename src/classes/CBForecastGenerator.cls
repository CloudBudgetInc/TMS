/**
 * Created by Alex JR on 9/8/2020.
 * This class generates quarter forecast from the actual data to Budget Apps tagged as Forecast
 * Amortization actual amounts are excluded
 * Actuals without Dimension1 and Dimension2 moves to _Unmapped Rest (Budget App)
 */

public with sharing class CBForecastGenerator implements Database.Batchable<SObject> {

    private String forecastPeriod;
    private String baseYearNumber;
    private String afterJobClassName;
    private static final Id budgetAppAmountDimensionId = [SELECT Id FROM cb4__CBDimension__c WHERE Name = 'Budget App Amount' LIMIT 1].Id;

    /**
     * The main method to upgrade Forecast Apps
     *
     * @param afterJobClassName
     */
    public static void runJob(String fcstPeriod, String afterJobClassName) {

        CBForecastGenerator fcGen = new CBForecastGenerator(fcstPeriod, null, afterJobClassName);
        Map<String, String> sMap = new Map<String, String>{
                'custom' => ' cb4__DimensionName__c = \'Budget App Amount\' AND cb4__Tag1__r.cb4__Tag8Name__c = \'Forecast\'  ' +
                        ' AND cb4__Tag3__r.cb4__Tag1Name__c = \'' + CBVariable.currentFY + '\' ' + getPeriodLimitQuery(fcstPeriod, null)
        };

        cb4.CBDeleteJob dj = new cb4.CBDeleteJob('cb4__CBTag__c', sMap, fcGen, 2000);
        Id batchId = Database.executeBatch(dj, 2000);
    }
    /*
    * The main method to upgrade Base budgets with Actuals
    */
    public static void runJob(String baseYearNumber, String actualsPeriod, String afterJobClassName) {

        CBForecastGenerator fcGen = new CBForecastGenerator(actualsPeriod, baseYearNumber, afterJobClassName);
        Map<String, String> sMap = new Map<String, String>{
                'custom' => ' cb4__DimensionName__c = \'Budget App Amount\' AND cb4__Tag1__r.cb4__Tag8Name__c = \'Base\'  ' +
                        ' AND cb4__Tag3__r.cb4__Tag1Name__c = \'' + baseYearNumber + '\' ' + getPeriodLimitQuery(actualsPeriod, baseYearNumber)
        };

        cb4.CBDeleteJob dj = new cb4.CBDeleteJob('cb4__CBTag__c', sMap, fcGen, 2000);
        Id batchId = Database.executeBatch(dj, 2000);
    }

    public CBForecastGenerator(String fcstPeriod, String baseYearNumber, String afterJobClassName) {
        this.afterJobClassName = afterJobClassName;
        this.forecastPeriod = fcstPeriod;
        this.baseYearNumber = baseYearNumber;
    }
    public Database.QueryLocator start(Database.BatchableContext context) {
        String q = 'SELECT cb4__Tag1__r.cb4__Tag6__c,cb4__Tag1__r.cb4__Tag7__c,cb4__Decimal1__c,cb4__Tag6Name__c,cb4__Tag7Name__c,' +
                'cb4__Tag3__c,cb4__Tag2__c,cb4__Tag6__c,cb4__Tag7__c,cb4__Tag8__c,cb4__Tag9__c,  ' +
                'cb4__Tag1__r.cb4__Tag3Name__c,cb4__Tag2Name__c,cb4__Tag2__r.cb4__Tag1Name__c, ' +
                'OwnerId ' +
                'FROM cb4__CBTag__c ' +
                'WHERE cb4__DimensionName__c = \'Entry Amount\' AND cb4__Tag1__r.cb4__Tag4Name__c = \'Actual\' ' +
                ' AND  cb4__Text1__c = \'main\' ' +
                ' AND cb4__Tag1__r.cb4__Tag1Name__c = \'' + CBVariable.currentFY + '\' ' + getPeriodLimitQuery(forecastPeriod, null);
        logJobStart(q);
        return Database.getQueryLocator(q);
    }
    public void execute(Database.BatchableContext context, List<cb4__CBTag__c> scope) {
        List<cb4__CBTag__c> tagsToUpsert = new List<cb4__CBTag__c>();
        Map<String, String> currFYPeriodsToBasePeriods = getCBVarPeriodToBasePeriodsMap(baseYearNumber);
        Map<String, cb4__CBTag__c> forecastAppsMap = getForecastAppsMap(forecastPeriod, baseYearNumber);
        String targetAppId;
        String ownerId;
        Boolean needDescription;
        Map<String, String> cityMap = remapDimension1UsingCity();
        Map<String, String> amortizationAccToAppMap = getAccountNumberToAmortizationAppIdMap(baseYearNumber); // key = amort account Id,  value = amort App Id

        for (cb4__CBTag__c t : scope) {
            if (t.cb4__Tag2__r.cb4__Tag1Name__c.contains('Amort') || t.cb4__Tag2__r.cb4__Tag1Name__c.contains('Allocated CS Cost')) {
                needDescription = false;
                targetAppId = amortizationAccToAppMap.get(t.cb4__Tag2Name__c.substring(0,4));
                t.cb4__Tag6__c = cityMap.get(t.cb4__Tag6__c);
            } else {
                targetAppId = forecastAppsMap.get(t.cb4__Tag6__c + String.valueOf(t.cb4__Tag7__c)) != null ? forecastAppsMap.get(t.cb4__Tag6__c + String.valueOf(t.cb4__Tag7__c)).Id : null; // select suitable Budget App
                ownerId = forecastAppsMap.get(t.cb4__Tag6__c + String.valueOf(t.cb4__Tag7__c)) != null ? forecastAppsMap.get(t.cb4__Tag6__c + String.valueOf(t.cb4__Tag7__c)).OwnerId : null;
                needDescription = false;
                if (targetAppId == null) {
                    targetAppId = forecastAppsMap.get(cityMap.get(t.cb4__Tag6__c) + String.valueOf(t.cb4__Tag7__c)) != null ? forecastAppsMap.get(cityMap.get(t.cb4__Tag6__c) + String.valueOf(t.cb4__Tag7__c)).Id : null; // try to change dim1 (street) to dim1(city general)
                    ownerId = forecastAppsMap.get(t.cb4__Tag6__c + String.valueOf(t.cb4__Tag7__c)) != null ? forecastAppsMap.get(t.cb4__Tag6__c + String.valueOf(t.cb4__Tag7__c)).OwnerId : null;
                }
                t.cb4__Tag6__c = targetAppId != null ? null : t.cb4__Tag6__c; // in general Budget App Amounts do not have dim1 and dim2
                t.cb4__Tag7__c = targetAppId != null ? null : t.cb4__Tag7__c; // in general Budget App Amounts do not have dim1 and dim2
            }
            if (targetAppId == null) { // flush to the _Unmapped Rest Budget App
                targetAppId = forecastAppsMap.get('nullnull') != null ? forecastAppsMap.get('nullnull').Id : null;
                ownerId = forecastAppsMap.get(t.cb4__Tag6__c + String.valueOf(t.cb4__Tag7__c)) != null ? forecastAppsMap.get(t.cb4__Tag6__c + String.valueOf(t.cb4__Tag7__c)).OwnerId : null;
                needDescription = true;
            }
            if (targetAppId == null) continue; // if _Unmapped Rest Budget App was not created
            tagsToUpsert.add(getNewBudgetAmount(t, t.cb4__Tag1__r.cb4__Tag3Name__c.toLowercase(), targetAppId, ownerId, needDescription, currFYPeriodsToBasePeriods));
        }

        if (tagsToUpsert.size() > 0) upsert tagsToUpsert;
    }
    public void finish(Database.BatchableContext context) {
        if (afterJobClassName != null) (Type.forName(afterJobClassName)).newInstance();
    }

    /**
     * Special map for mapping Streets to City General if some actual entry Dim1 + Dim2 pair doesn't have the same pair in the Budget App list
     * @return key - CB Dim1 Id (Street), value - CB Dim1 Id (General City)
     */
    public static Map<String, String> remapDimension1UsingCity() {
        Map<String, String> r = new Map<String, String>();
        Set<String> setOfGeneralDim1 = new Set<String>();
        Map<String, String> cityMap = new Map<String, String>();// key - general city Id,  value =  Dim1 Id
        for (cb4__CBTag__c dim1 : [SELECT Id, cb4__Tag6__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'CB_FF1' AND (Name LIKE '%General%' OR Name LIKE '%for allocation%')]) cityMap.put(dim1.cb4__Tag6__c, dim1.Id);
        for (cb4__CBTag__c dim1 : [SELECT Id, Name, cb4__Tag6Name__c, cb4__Tag6__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'CB_FF1']) r.put(dim1.Id, cityMap.get(dim1.cb4__Tag6__c));
        return r;
    }

    public static Map<String, String> getAccountNumberToAmortizationAppIdMap(String baseYNumber) {
        Map<String, String> r = new Map<String, String>();
        for (cb4__CBTag__c amortApp : [
                SELECT Id, cb4__TagLabel__c
                FROM cb4__CBTag__c
                WHERE cb4__DimensionName__c = 'Budget App' AND cb4__Tag8Name__c = :(String.isNotBlank(baseYNumber) ? 'Base' : 'Forecast')
                AND cb4__Tag3Name__c = :(String.isNotBlank(baseYNumber) ? baseYNumber : CBVariable.currentFY)
                AND (cb4__Tag1Name__c LIKE '%Amort%' OR cb4__Tag1__r.cb4__Tag1Name__c LIKE '%Amort%' OR cb4__Tag1Name__c LIKE '%Allocated Costs%')
        ]) r.put(amortApp.cb4__TagLabel__c.substring(0,4), amortApp.Id);
        return r;
    }

    /////// PRIVATE METHODS ///////
    /**
     * key = Application CBFF1 Id + CBFF2 Id
     * value = Forecast Application Record
     * @return list of the forecast Apps of the calculated BY
     */
    public static Map<String, cb4__CBTag__c> getForecastAppsMap(String forecastPeriod, String baseYNumber) {
        Integer quarterNumber = getQuarterNumber(forecastPeriod);
        List<cb4__CBTag__c> apps = new List<cb4__CBTag__c>();
        Map<String, cb4__CBTag__c> r = new Map<String, cb4__CBTag__c>();
        for (cb4__CBTag__c t : [
                SELECT Id, cb4__TagLabel__c, cb4__Tag6__c, cb4__Tag7__c, cb4__Decimal6__c, OwnerId
                FROM cb4__CBTag__c
                WHERE cb4__DimensionName__c = 'Budget App'
                AND cb4__Tag8Name__c = :(String.isNotBlank(baseYNumber) ? 'Base' : 'Forecast')
                AND cb4__Tag3Name__c = :(String.isNotBlank(baseYNumber) ? baseYNumber : CBVariable.currentFY)
        ]) {
            if (t.cb4__Tag6__c == null && t.cb4__Tag7__c == null) {
                if (!t.cb4__TagLabel__c.contains('_Unmapped')) continue; // only Unmapped application can be considered null null to contain all the actuals without respective apps
            }
            r.put(t.cb4__Tag6__c + String.valueOf(t.cb4__Tag7__c), t);
            if (t.cb4__Decimal6__c == null || t.cb4__Decimal6__c < quarterNumber) t.cb4__Decimal6__c = quarterNumber; // the number of the forecast Budget Apps locked columns
            if(String.isNotBlank(baseYNumber)) t.cb4__Decimal6__c = 0;
            apps.add(t);
        }
        update apps;
        return r;
    }

    private static void logJobStart(String mainQuery) {
        cb4.CBConsole.setLog('OTHER', 'Forecast Generator Job Started', 'job start report');
        cb4.CBConsole.addLog('@B->  Job query = ' + mainQuery);
        cb4.CBConsole.insertLog();
    }

    /**
     * @return the number of quarters must be locked
     */
    public static Integer getQuarterNumber(String forecastPeriod) {
        Map<Integer, Integer> monthToQuarterNumberMap = new Map<Integer, Integer>{
                4 => 0,
                5 => 0,
                6 => 0,
                7 => 3,
                8 => 3,
                9 => 3,
                10 => 6,
                11 => 6,
                12 => 6,
                1 => 9,
                2 => 9,
                3 => 9,
                -1 => 12
        };
        Integer monthNumber = 4;
        if (forecastPeriod == 'upToDate' || forecastPeriod == 'YT end of last Q') monthNumber = System.today().month(); else if (forecastPeriod == 'Q1') monthNumber = 7; else if (forecastPeriod == 'Q2') monthNumber = 10; else if (forecastPeriod == 'Q3') monthNumber = 1; else if (forecastPeriod == 'Q4') monthNumber = -1;
        else{
            Date periodDate = [SELECT Id, cb4__Start__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Period' AND Name = :forecastPeriod].cb4__Start__c;
            return periodDate.month() - 3;
        }
        return monthToQuarterNumberMap.get(monthNumber);
    }

    /**
     * @param forecastPeriod upToDate - from the beginning of the calculated year to the current quarter
     * @return
     */
    public static String getPeriodLimitQuery(String forecastPeriod, String baseYNumber) {
        Map<Integer, Integer> monthToLastQuarterMonthMap = new Map<Integer, Integer>{
                4 => 0,
                5 => 0,
                6 => 0,
                7 => 6,
                8 => 6,
                9 => 6,
                10 => 9,
                11 => 9,
                12 => 9,
                1 => 12,
                2 => 12,
                3 => 12
        };
        Date sDate = String.isNotBlank(baseYNumber) ? Date.newInstance(Integer.valueOf(baseYNumber) - 1, 4, 1) : Date.newInstance(Integer.valueOf(CBVariable.currentFY) - 1, 4, 1);
        Date eDate;

        if (forecastPeriod == 'upToDate' || forecastPeriod == 'YT end of last Q') {
            Integer currentMonth = System.today().month();
            Integer endYear = currentMonth > 3 ? String.isNotBlank(baseYNumber) ? Integer.valueOf(baseYNumber) - 1 : Integer.valueOf(CBVariable.currentFY) - 1 : String.isNotBlank(baseYNumber) ? Integer.valueOf(baseYNumber): Integer.valueOf(CBVariable.currentFY);
            Integer lastQuarterMonth = monthToLastQuarterMonthMap.get(currentMonth);
            eDate = Date.newInstance(endYear, lastQuarterMonth, 1);
        } else if (forecastPeriod == 'Q1') {
            eDate = sDate.addMonths(2);
        } else if (forecastPeriod == 'Q2') {
            sDate = sDate.addMonths(3);
            eDate = sDate.addMonths(2);
        } else if (forecastPeriod == 'Q3') {
            sDate = sDate.addMonths(6);
            eDate = sDate.addMonths(2);
        } else if (forecastPeriod == 'Q4') {
            sDate = sDate.addMonths(9);
            eDate = sDate.addMonths(2);
        } else {
            cb4__CBTag__c period = [SELECT Id, cb4__Start__c, cb4__End__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Period' AND Name = :forecastPeriod];
            Date periodSDate = period.cb4__Start__c;
            Date periodEDate = period.cb4__End__c;
            sDate = Date.newInstance(Integer.valueOf(String.isNotBlank(baseYNumber) ? baseYNumber : CBVariable.currentFY) - (periodSDate.month() < 4 ? 0 : 1), periodSDate.month(), periodSDate.day());
            eDate = Date.newInstance(Integer.valueOf(String.isNotBlank(baseYNumber) ? baseYNumber : CBVariable.currentFY) - (periodEDate.month() < 4 ? 0 : 1), periodEDate.month(), periodEDate.day());
        }
        System.debug('---****----');
        System.debug(' AND cb4__Tag3__r.cb4__Start__c >= ' + String.valueOf(sDate) + ' AND cb4__Tag3__r.cb4__Start__c <= ' + String.valueOf(eDate));

        return ' AND cb4__Tag3__r.cb4__Start__c >= ' + String.valueOf(sDate) + ' AND cb4__Tag3__r.cb4__Start__c <= ' + String.valueOf(eDate);
    }

    /**
     *
     *
     * @param t Entry Amount
     * @param type income / expense
     * @param appId parent App Id
     *
     * @return
     */
    private static cb4__CBTag__c getNewBudgetAmount(cb4__CBTag__c t, String type, String appId, String oId, Boolean needDescription, Map<String, String> currPeriodToBasePeriod) {
        return new cb4__CBTag__c(
                cb4__Text1__c = type,
                cb4__Text2__c = type,
                cb4__Text3__c = t.cb4__Tag2Name__c + '     ' + t.cb4__Tag2__r.cb4__Tag1Name__c, // line title
                cb4__Text4__c = needDescription ? 'Dim1:"' + t.cb4__Tag6Name__c + '" & Dim2:"' + t.cb4__Tag7Name__c + '"' : null, // line description
                cb4__Text5__c = 'COPY',
                cb4__Tag1__c = appId,
                cb4__Tag2__c = t.cb4__Tag2__c,
                cb4__Tag3__c = currPeriodToBasePeriod.containsKey(t.cb4__Tag3__c) ? currPeriodToBasePeriod.get(t.cb4__Tag3__c) : t.cb4__Tag3__c,
                cb4__Tag6__c = t.cb4__Tag6__c,
                cb4__Tag7__c = t.cb4__Tag7__c,
                cb4__Decimal1__c = t.cb4__Decimal1__c,
                cb4__Dimension__c = budgetAppAmountDimensionId,
                OwnerId = oId != null ? oId : t.OwnerId
        );

    }

    private static Map<String, String> getCBVarPeriodToBasePeriodsMap(String baseYNumber){
        Map<String, String> monthToBasePeriodId = new Map<String, String>();
        Map<String, String> currFYIdToBasePeriodId = new Map<String, String>();
        if(String.isNotBlank(baseYNumber)) {
            for (cb4__CBTag__c basePeriod : [SELECT Id, cb4__Start__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Period' AND cb4__Tag1Name__c = :baseYNumber]) {
                monthToBasePeriodId.put(String.valueOf(basePeriod.cb4__Start__c.month()), basePeriod.Id);
            }
            for (cb4__CBTag__c currFYperiod : [SELECT Id, cb4__Start__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Period' AND cb4__Tag1Name__c = :CBVariable.currentFY]) {
                currFYIdToBasePeriodId.put(currFYperiod.Id, monthToBasePeriodId.get(String.valueOf(currFYperiod.cb4__Start__c.month())));
            }
        }
        return  currFYIdToBasePeriodId;
    }
    /////// PRIVATE METHODS ///////

}