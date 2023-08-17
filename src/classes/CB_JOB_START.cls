/**
 * Created by Alex JR on 9/10/2020.
 */

global with sharing class CB_JOB_START implements Queueable {

    global CB_JOB_START() {
        System.enqueueJob(new CB_JOB_START(null));
        CBVariable.setStep(1);
    }
    global CB_JOB_START(Object arg) {

    }
    public void execute(QueueableContext context) {
        cb4.CBFFIntegration.synchronizeAnalytics();
        CBCityMapping.run();
        CBTMSIntegration.syncBudgetDepartments();
        deleteOldCBRBAndRunFFIntegration();
    }
    private static void deleteOldCBRBAndRunFFIntegration() {
        Id configId = [SELECT Id FROM cb4__CBTag__c WHERE cb4__Dimension__c = :cb4.CBUtils.dimensionNameIdMap.get('CB_FF Mapping Configuration') AND Name = 'Default Configuration' LIMIT 1][0].Id;
        Id currentFYId = [SELECT Id FROM cb4__CBTag__c WHERE cb4__Dimension__c = :cb4.CBUtils.dimensionNameIdMap.get('Budget Year') AND Name = :CBVariable.currentFY LIMIT 1][0].Id;
        cb4.CBFFIntegration FFIntegrate = new cb4.CBFFIntegration(configId, CBVariable.startFY, CBVariable.endFY, 'CB_JOB_STEP_1');
        Map<String, String> sMap = new Map<String, String>{
                'custom' => ' cb4__Dimension__c = \'' + cb4.CBUtils.dimensionNameIdMap.get('CB Reporting Balance') + '\'  AND cb4__Tag4__c = \'' + currentFYId + '\' '
        };
        cb4.CBDeleteJob dj = new cb4.CBDeleteJob('cb4__CBTag__c', sMap, FFIntegrate, 2000);
        Id batchId = Database.executeBatch(dj, 2000);
    }
}