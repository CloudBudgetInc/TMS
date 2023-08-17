/**
 * Created by Alex JR on 9/10/2020.
 */

global with sharing class CB_JOB_STEP_1 implements Queueable {

    global CB_JOB_STEP_1() {
        System.enqueueJob(new CB_JOB_STEP_1(null));
        CBVariable.setStep(2);
    }
    global CB_JOB_STEP_1(Object arg) {

    }
    public void execute(QueueableContext context) {
        run();
    }
    public static void run() {
        List<String> PRIds = new List<String>();
        String q = 'SELECT Id FROM cb4__CBPostingRule__c WHERE Name LIKE \'% ' + CBVariable.currentFY + '%\' ';
        for (cb4__CBPostingRule__c pr : Database.query(q)) PRIds.add(pr.Id);
        cb4.CBController.recalculateSelectedPostingRules(PRIds, 'CB_JOB_STEP_2');
    }
}