/**
 * Created by Alex JR on 9/10/2020. 
 */

global with sharing class CB_JOB_STEP_5 implements Queueable {

    global CB_JOB_STEP_5() {
        System.enqueueJob(new CB_JOB_STEP_5(null));
        CBVariable.setStep(6);
    }
    global CB_JOB_STEP_5(Object arg) {

    }
    public void execute(QueueableContext context) {
        runDeletingPlannedFFRB();
    }

    private static void runDeletingPlannedFFRB() {
        String cbalancerulewhere = 'CBRB ' + CBVariable.currentFY + ' Base';
        List<cb4__CBalanceRule__c> CBalRule = [SELECT Id FROM cb4__CBalanceRule__c WHERE cb4__Label__c = :cbalancerulewhere];
        cb4.CBFFIntegrationBackward FFBackwardIntegrationJob = null;
        if(!CBalRule.isEmpty()) {
            Id CBalRuleId = CBalRule[0].Id;
            String intDefId = [SELECT Id FROM c2g__codaIntersectDefinition__c WHERE c2g__FullAccountingCode__c = true LIMIT 1].Id;
            String FFRBType = 'Budget';
            FFBackwardIntegrationJob = new cb4.CBFFIntegrationBackward(CBVariable.startFY, CBVariable.endFY, intDefId, CBalRuleId, FFRBType, 'CB_JOB_STEP_6');
        }
        Map<String, String> sMap = new Map<String, String>{
                'custom' => ' (c2g__Type__c = \'Budget\' OR c2g__Type__c = \'Forecast\') AND c2g__YearNumber__c = ' + CBVariable.currentFY + ' '
        };
        cb4.CBDeleteJob dj = new cb4.CBDeleteJob('c2g__ReportingBalance__c', sMap, FFBackwardIntegrationJob, 500);
        Id batchId = Database.executeBatch(dj, 2000);
    }
}