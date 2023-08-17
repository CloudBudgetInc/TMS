/**
 * Created by Alex JR on 9/8/2020.
 * This class spread BDG Id and Owner ID between Actual Entries
 */

public with sharing class CBEntryMapping implements Database.Batchable<SObject> {

    private String afterJobClassName;
    private Map<String, String> bridgeDim1Dim2Map1 = CBService.getBridgeDim1Dim2Map(1); // just 1 Needed
    private Map<String, String> bridgeDim1Dim2Map2 = CBService.getBridgeDim1Dim2Map(2); // just 1 Needed
    private Map<String, String> bridgeDim1Dim2Map3 = CBService.getBridgeDim1Dim2Map(3); // just 1 Needed
    private Map<String, String> BDGToOwnerMap = CBService.getBDGToOwnerMap();
    private static Id CURRENT_FY_ID = [SELECT Id FROM cb4__CBTag__c WHERE cb4__Dimension__c = :cb4.CBUtils.dimensionNameIdMap.get('Budget Year') AND Name = :CBVariable.currentFY LIMIT 1][0].Id;
    private static Id ACTUAL_ENTRY_CLASS_ID = [SELECT Id FROM cb4__CBTag__c WHERE cb4__Dimension__c = :cb4.CBUtils.dimensionNameIdMap.get('Entry Class') AND Name = 'Actual'][0].Id;

    public CBEntryMapping(String afterJobClassName) {
        this.afterJobClassName = afterJobClassName;
    }
    public Database.QueryLocator start(Database.BatchableContext context) {
        String q = 'SELECT cb4__Tag1__c,cb4__Tag6__c,cb4__Tag7__c ' +
                'FROM cb4__CBTag__c ' +
                'WHERE cb4__Dimension__c = \'' + cb4.CBUtils.dimensionNameIdMap.get('Entry Amount') + '\' AND cb4__Tag1__r.cb4__Tag4__c = \'' + ACTUAL_ENTRY_CLASS_ID + '\'  ' +
                'AND cb4__Tag1__r.cb4__Tag1__c = \'' + CURRENT_FY_ID + '\' ';
        return Database.getQueryLocator(q);
    }
    public void execute(Database.BatchableContext context, List<cb4__CBTag__c> scope) {
        List<cb4__CBTag__c> tagsToUpdate = new List<cb4__CBTag__c>();
        Set<String> entryIds = new Set<String>();
        for (cb4__CBTag__c t : scope) entryIds.add(t.cb4__Tag1__c);
        Map<String, cb4__CBTag__c> entryMap = new Map<String, cb4__CBTag__c>();
        for (cb4__CBTag__c t : [SELECT Id FROM cb4__CBTag__c WHERE Id IN:entryIds]) entryMap.put(t.Id, t);

        for (cb4__CBTag__c t : scope) {
            String CBBRD1Lvl = bridgeDim1Dim2Map1.get(t.cb4__Tag6__c + String.valueOf(t.cb4__Tag7__c));
            String CBBRD2Lvl = bridgeDim1Dim2Map2.get(t.cb4__Tag6__c + String.valueOf(t.cb4__Tag7__c));
            String CBBRD3Lvl = bridgeDim1Dim2Map3.get(t.cb4__Tag6__c + String.valueOf(t.cb4__Tag7__c));
            if (CBBRD1Lvl != null) {
                String bdgId = CBBDGMapping.getBDGId(CBBRD1Lvl, CBBRD2Lvl, CBBRD3Lvl);
                cb4__CBTag__c entry = entryMap.get(t.cb4__Tag1__c);
                entry.cb4__Tag9__c = bdgId;

                String ownerId = BDGToOwnerMap.get(bdgId);
                if (ownerId != null) {
                    t.OwnerId = ownerId;
                    entry.OwnerId = ownerId;
                }
                if (bdgId != null) tagsToUpdate.add(t);
            }
        }
        update tagsToUpdate;
        update entryMap.values();
    }

    public void finish(Database.BatchableContext context) {
        if (afterJobClassName != null) (Type.forName(afterJobClassName)).newInstance();
    }


}