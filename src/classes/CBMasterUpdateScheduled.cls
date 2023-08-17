/**
 * Created by Alex JR on 9/25/2020.
 */

global with sharing class CBMasterUpdateScheduled implements Schedulable {

    global void execute(SchedulableContext SC) {
        CBTMSController.runMasterUpdateServer(null);
        sendEmailToAdmin();
    }

    public static void sendEmailToAdmin() {
        String emailRecipients = CBVariable.emailRecipients;
        if (emailRecipients == null || emailRecipients == '') return;

        String[] toAddresses = CBVariable.emailRecipients.split(',');

        Messaging.reserveSingleEmailCapacity(toAddresses.size());


        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        /*String[] toAddresses = new String[]{
                'alugovoi@cloudbudget.com'
        };*/


        /*String[] ccAddresses = new String[]{
                'lugvas1@gmail.com'
        };*/

        mail.setToAddresses(toAddresses);
        //mail.setCcAddresses(ccAddresses);

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