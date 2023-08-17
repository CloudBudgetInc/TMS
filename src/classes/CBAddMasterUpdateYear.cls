global with sharing class CBAddMasterUpdateYear implements Schedulable  {
    global void execute(SchedulableContext SC) {
        addYear();
        CB_JOB_START start = new CB_JOB_START();
        sendEmailToAdmin();
    }

    public static void addYear(){
        // Get current Financial Year and convert it to Integer
        Integer currFY = Integer.valueOf(CBVariable.currentFY);
        // Set next Financial Year as current
        CBVariable.saveCurrentFY(String.valueOf(currFY + 1));
    }

    public static void sendEmailToAdmin() {
        String emailRecipients = CBVariable.emailRecipients;
        if (emailRecipients == null || emailRecipients == '') return;

        String[] toAddresses = CBVariable.emailRecipients.split(',');

        Messaging.reserveSingleEmailCapacity(toAddresses.size());


        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setToAddresses(toAddresses);

        mail.setReplyTo('alugovoi@cloudbudget.com');

        mail.setSenderDisplayName('CloudBudget2.0 Support');

        mail.setSubject('"The Mustard Seed" org runs master data refresh jobs');

        mail.setBccSender(false);

        mail.setUseSignature(false);

        mail.setPlainTextBody('Start date: ' + System.today() + ' You will be additionally notified at the end of the process');

        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                mail
        });
    }
}