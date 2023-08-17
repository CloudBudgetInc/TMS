/**
 * Created by Alex JR on 9/24/2020.
 */

public with sharing class CBCityMapping {

    public static void run() {

        Id cityDimensionId = [SELECT Id FROM cb4__CBDimension__c WHERE Name = 'City' LIMIT 1].Id;

        Map<String, String> FFDim1Map = new Map<String, String>();
        Set<String> cityNames = new Set<String>();
        for (c2g__codaDimension1__c d : [SELECT Id, ESi_Location_Grouping__c FROM c2g__codaDimension1__c LIMIT 5000]) {
            FFDim1Map.put(d.Id, d.ESi_Location_Grouping__c);
            cityNames.add(d.ESi_Location_Grouping__c);
        }

        List<cb4__CBTag__c> cityToUpdate = new List<cb4__CBTag__c>();

        Set<String> existedCityNames = new Set<String>();
        for (cb4__CBTag__c t : [SELECT Id, Name FROM cb4__CBTag__c WHERE cb4__Dimension__c = :cityDimensionId LIMIT 5000]) existedCityNames.add(t.Name);
        for (String name : cityNames) {
            if (existedCityNames.contains(name)) continue;
            cityToUpdate.add(new cb4__CBTag__c (cb4__Dimension__c = cityDimensionId, Name = name));
            cityNames.add(name);
        }
        insert cityToUpdate;

        Map<String, String> cityMap = new Map<String, String>();
        for (cb4__CBTag__c t : [SELECT Id, Name FROM cb4__CBTag__c WHERE cb4__Dimension__c = :cityDimensionId LIMIT 5000]) cityMap.put(t.Name, t.Id);

        List<cb4__CBTag__c> CBFF1ToUpdate = new List<cb4__CBTag__c>();
        for (cb4__CBTag__c t : [SELECT Id, cb4__Tag6__c, cb4__ExtId__c FROM cb4__CBTag__c WHERE cb4__Dimension__c = :cb4.CBUtils.dimensionNameIdMap.get('CB_FF1') LIMIT 10000]) {
            String cityName = FFDim1Map.get(t.cb4__ExtId__c);
            if(t.cb4__Tag6__c == cityMap.get(cityName)) continue;
            t.cb4__Tag6__c = cityMap.get(cityName);
            CBFF1ToUpdate.add(t);
        }
        update CBFF1ToUpdate;

    }

}