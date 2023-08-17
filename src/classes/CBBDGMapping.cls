/**
 * Created by Alex JR on 9/7/2020.
 */

public with sharing class CBBDGMapping {

    public static Map<String, String> BDGMap {
        get {
            if (BDGMap == null) BDGMap = getBDGMap();
            return BDGMap;
        }
        set;
    }

    /**
     *
     * @param rd1  CB or TMS Reporting Department level 1
     * @param rd1  CB or TMS Reporting Department level 2
     * @param rd1  CB or TMS Reporting Department level 3
     *
     * @return CB BDG Id
     */
    public static String getBDGId(String rd1, String rd2, String rd3) {
        String r = rd1 == null ? null : BDGMap.get(rd1);
        if (r != null) return r;
        r = rd2 == null ? null : BDGMap.get(rd2);
        if (r != null) return r;
        return BDGMap.get(rd3);
    }


    ////// PRIVATE METHODS ///////
    private static Map<String, String> getBDGMap() {
        Map<String, String> r = new Map<String, String>();
        Map<String, String> CBToTMS = new Map<String, String>();
        for (cb4__CBTag__c t : [SELECT Id, cb4__ExtId__c FROM cb4__CBTag__c WHERE cb4__Dimension__c = :cb4.CBUtils.dimensionNameIdMap.get(CBVariable.CBBRDName) LIMIT 5000]) CBToTMS.put(t.cb4__ExtId__c, t.Id);
        for (CBBDGMapping__c m : [SELECT BDG__c, ReportingDepartment1__c, ReportingDepartment2__c, ReportingDepartment3__c FROM CBBDGMapping__c LIMIT 5000]) {
            if (m.ReportingDepartment1__c != null) {
                r.put(m.ReportingDepartment1__c, m.BDG__c);
                r.put(CBToTMS.get(m.ReportingDepartment1__c), m.BDG__c);
            }
            if (m.ReportingDepartment2__c != null) {
                r.put(m.ReportingDepartment2__c, m.BDG__c);
                r.put(CBToTMS.get(m.ReportingDepartment2__c), m.BDG__c);
            }
            if (m.ReportingDepartment3__c != null) {
                r.put(m.ReportingDepartment3__c, m.BDG__c);
                r.put(CBToTMS.get(m.ReportingDepartment3__c), m.BDG__c);
            }
        }
        return r;
    }

    ////// PRIVATE METHODS ///////

}