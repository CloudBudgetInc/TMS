global with sharing class CB_JOB_STEP_7  implements Queueable {
    global CB_JOB_STEP_7() {
        System.enqueueJob(new CB_JOB_STEP_7(null));
        CBVariable.setStep(8);
    }
    global CB_JOB_STEP_7(Object arg) {

    }
    public void execute(QueueableContext context) {
        sendEmailToAdmin();
        Id jobId = Database.executeBatch(new CBReportingBalancesProcessing());
    }

    public static void sendEmailToAdmin() {
        String[] toAddresses = CBVariable.emailRecipients.split(',');
        Messaging.reserveSingleEmailCapacity(toAddresses.size());
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        mail.setReplyTo('alugovoi@cloudbudget.com');
        mail.setSenderDisplayName('CloudBudget2.0 Support');
        mail.setSubject('"The Mustard Seed" nightly jobs finished');
        mail.setBccSender(false);
        mail.setUseSignature(false);
        mail.setPlainTextBody('Start date: ' + System.today() + ' You will be additionally notified at the end of the process');
        if(!Test.isRunningTest()){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                    mail
            });
        }
    }
}