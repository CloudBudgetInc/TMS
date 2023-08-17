@isTest
public class PicklistValuesService_Test {

    @isTest
    public static void testPicklists()
    {
        Test.startTest();

        PicklistValuesService.getPicklistValues(new List<String>{'Contact.TMS_City__c','Contact.Sub_Type__c','Account.RecordType'});

        Test.stopTest();
    }
}