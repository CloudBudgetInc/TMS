/**
 * Created by Alex JR on 9/6/2020.
 * Global variables of the CB2 integration
 */

public with sharing class CBVariable {

    private static final Integer startMonth = 4;

    public static final String CBBRDName = 'Budget Reporting Department';

    public static String currentFY {
        get {
            if (currentFY == null) currentFY = [SELECT Id, FY__c FROM CBGlobalVariable__c][0].FY__c;
            return currentFY;
        }
        set;
    }

    public static Decimal step{
        get{
            if(step == null) step = [SELECT Step__c FROM CBGlobalVariable__c][0].Step__c;
            return step;
        }
        set;
    }

    public static String fcstLockSettings {
        get {
            if (fcstLockSettings == null) fcstLockSettings = [SELECT Id, ForecastPeriodsLockSettings__c FROM CBGlobalVariable__c][0].ForecastPeriodsLockSettings__c;
            return fcstLockSettings;
        }
        set;
    }

    public static Date startFY {
        get {
            if (startFY == null) startFY = Date.newInstance(Integer.valueOf(currentFY) - 1, startMonth, 1);
            return startFY;
        }
        set;
    }

    public static Date endFY {
        get {
            if (endFY == null) endFY = (Date.newInstance(Integer.valueOf(currentFY), startMonth, 1)).addDays(-1);
            return endFY;
        }
        set;
    }

    public static Datetime lastUpdateDate {
        get {
            List<CBGlobalVariable__c> tmp = [SELECT LastUpdateDate__c FROM CBGlobalVariable__c];
            if (tmp.size() == 0 || tmp[0].LastUpdateDate__c == null) saveLastUpdateDate();
            return [SELECT LastUpdateDate__c FROM CBGlobalVariable__c][0].LastUpdateDate__c;
        }
        set;
    }

    public static String emailRecipients {
        get {
            if (emailRecipients == null) emailRecipients = [SELECT EmailRecipients__c FROM CBGlobalVariable__c][0].EmailRecipients__c;
            return emailRecipients;
        }
        set;
    }

    public static Integer getMinutesFromTheUpdateDate() {
        System.debug(lastUpdateDate);
        return Integer.valueOf((System.now().getTime() - lastUpdateDate.getTime()) / 1000 / 60);
    }

    /**
     * @param fy  "2020" as an example
     */
    public static void saveCurrentFY(String fy) {
        if (fy == null || fy == '') return;
        CBGlobalVariable__c CBVariable = [SELECT Id, FY__c FROM CBGlobalVariable__c LIMIT 1];
        if (CBVariable == null) CBVariable = new CBGlobalVariable__c();
        CBVariable.FY__c = fy;
        upsert CBVariable;
    }

    public static void saveEmailRecipients(String emailRecipients) {
        CBGlobalVariable__c CBVariable = [SELECT Id, EmailRecipients__c FROM CBGlobalVariable__c LIMIT 1];
        if (CBVariable == null) CBVariable = new CBGlobalVariable__c();
        CBVariable.EmailRecipients__c = emailRecipients;
        upsert CBVariable;
    }

    public static void saveLastUpdateDate() {
        CBGlobalVariable__c CBVariable = [SELECT Id, LastUpdateDate__c FROM CBGlobalVariable__c LIMIT 1];
        if (CBVariable == null) CBVariable = new CBGlobalVariable__c();
        CBVariable.LastUpdateDate__c = System.now();
        upsert CBVariable;
    }

    public static void saveForecastLockPeriodsSettings(String fcstPeriod){
        CBGlobalVariable__c CBVar = [SELECT Id, ForecastPeriodsLockSettings__c FROM CBGlobalVariable__c LIMIT 1];
        Map<String, String> fcstPeriodSetting = new Map<String, String>();
        if(CBVar.ForecastPeriodsLockSettings__c != null) fcstPeriodSetting = (Map<String, String>) JSON.deserialize(CBVar.ForecastPeriodsLockSettings__c, Map<String, String>.class);
        fcstPeriodSetting.put(fcstPeriod, String.valueOf(Datetime.now()));
        CBVar.ForecastPeriodsLockSettings__c = JSON.serialize(fcstPeriodSetting);
        upsert CBVar;
    }

    public static void setStep(Decimal sNum){
        CBGlobalVariable__c gv = [SELECT Id, Step__c FROM CBGlobalVariable__c][0];
        gv.Step__c = sNum;
        update gv;
    }

}