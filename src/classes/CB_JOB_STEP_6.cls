global with sharing class CB_JOB_STEP_6  implements Queueable {
    global CB_JOB_STEP_6() {
        System.enqueueJob(new CB_JOB_STEP_6(null));
        CBVariable.setStep(7);
    }
    global CB_JOB_STEP_6(Object arg) {

    }
    public void execute(QueueableContext context) {
        String cbalancerulewhere = 'CBRB ' + CBVariable.currentFY + ' Forecast';
        List<cb4__CBalanceRule__c> CBalRule = [SELECT Id FROM cb4__CBalanceRule__c WHERE cb4__Label__c = :cbalancerulewhere];
        if(!CBalRule.isEmpty()) {
            Id CBalRuleId = CBalRule[0].Id;
            String intDefId = [SELECT Id FROM c2g__codaIntersectDefinition__c WHERE c2g__FullAccountingCode__c = true LIMIT 1].Id;
            String FFRBType = 'Forecast';
            cb4.CBFFIntegrationBackward FFBackwardIntegrationJob = new cb4.CBFFIntegrationBackward(CBVariable.startFY, CBVariable.endFY, intDefId, CBalRuleId, FFRBType, 'CB_JOB_STEP_7');
            Id batchId = Database.executeBatch(FFBackwardIntegrationJob, 500);
        }
    }
}