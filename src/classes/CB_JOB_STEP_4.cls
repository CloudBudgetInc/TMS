/**
 * Created by Alex JR on 9/10/2020.
 */

global with sharing class CB_JOB_STEP_4 implements Queueable {

    global CB_JOB_STEP_4() {
        System.enqueueJob(new CB_JOB_STEP_4(null));
        CBVariable.setStep(5);
    }
    global CB_JOB_STEP_4(Object arg) {

    }
    public void execute(QueueableContext context) {
        CBalanceGenerator.runJobs('CB_JOB_STEP_5');
    }
}