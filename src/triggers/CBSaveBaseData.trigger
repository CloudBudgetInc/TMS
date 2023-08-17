/**
 * Created by Alex JR on 10/8/2020.
 */

trigger CBSaveBaseData on cb4__CBTag__c (before delete) {

    if (Trigger.isDelete) {
        for (cb4__CBTag__c tagOld : Trigger.Old) {
            //if (tagOld.cb4__DimensionName__c == 'Budget App' && tagOld.cb4__Tag3Name__c == '2021' && tagOld.cb4__Tag8Name__c == 'Base') tagOld.AddError('Protected By Trigger');
            //if (tagOld.cb4__DimensionName__c == 'Budget App Amount' && tagOld.cb4__Tag1__r.cb4__Tag3Name__c == '2021' && tagOld.cb4__Tag1__r.cb4__Tag8Name__c == 'Base') tagOld.AddError('Protected By Trigger');
        }
    }

}