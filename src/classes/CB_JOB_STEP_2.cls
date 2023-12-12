/**
 * Created by Alex JR on 9/10/2020.
 */

global with sharing class CB_JOB_STEP_2 implements Queueable {

    global CB_JOB_STEP_2() {
        System.enqueueJob(new CB_JOB_STEP_2(null));
        CBVariable.setStep(3);
    }
    global CB_JOB_STEP_2(Object arg) {

    }
    public void execute(QueueableContext context) {
        Id jobId = Database.executeBatch(new CBEntryMappingV2('CB_JOB_STEP_3'), 400);
    }
}