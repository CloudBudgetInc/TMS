/**
 * Created by Alex JR on 9/10/2020.
 *
 * Recalculate CBalance rule of the current FY except of LVL1..3 Reports
 */

global with sharing class CB_JOB_STEP_3 implements Queueable {

    global CB_JOB_STEP_3() {
        System.enqueueJob(new CB_JOB_STEP_3(null));
        CBVariable.setStep(4);
    }
    global CB_JOB_STEP_3(Object arg) {

    }
    public void execute(QueueableContext context) {
        List<String> simpleCBRuleIds = new List<String>();
        String q = 'SELECT Id FROM cb4__CBalanceRule__c WHERE cb4__Label__c LIKE \'%' + CBVariable.currentFY + '%\' ' +
                'AND (NOT cb4__Label__c LIKE \'%LVL%\')';
        for (cb4__CBalanceRule__c cbr : Database.query(q)) simpleCBRuleIds.add(cbr.Id);
        if (simpleCBRuleIds.size() > 0) cb4.CBController.recalculateSpecifiedCBalances(simpleCBRuleIds, 'CB_JOB_STEP_4');
    }
}