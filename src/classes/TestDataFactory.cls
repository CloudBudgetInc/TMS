@isTest
public with sharing class TestDataFactory {

    public static Contact createContact() {
        Contact con = new Contact(firstName='Test', lastName='Contact', TMS_City__c='Calgary');
        insert con;
        return con;
    }

    public static c2g__codaDimension2__c createDim2() {
        c2g__codaDimension2__c dim2 = new c2g__codaDimension2__c(
            name = 'autotest',
            c2g__ReportingCode__c = 'autotest',
            ESi_Statement_of_Ops_Expense_Group__c = 'Administration'
        );
        insert dim2;
        return dim2;
    }

    public static Campaign createCampaign(String appealId) {
        Campaign cam = new Campaign(
            name = 'testAppeal',
            type = 'Emails',
            isActive = true,
            Campaign_Appeal_ID__c = appealId,
            Staff_Accountability__c = createDim2().Id
        );
        insert cam;
        return cam;
    }

    public static ChargentBase__Gateway__c createGateway(string gatewayName){
        ChargentBase__Gateway__c g = new ChargentBase__Gateway__c(
            ChargentBase__Accounting_Seed_Integration__c = false,
            ChargentBase__Active__c = true,
            ChargentBase__Allow_No_Hit_Transactions__c = true,
            ChargentBase__Allow_Unlinked_Refund__c = false,
            ChargentBase__Approve_Soft_Rejects__c = false,
            ChargentBase__Available_Card_Types__c = 'Visa;Mastercard;Discover;American Express',
            ChargentBase__Available_Currencies__c = 'Canadian dollar',
            ChargentBase__Available_Payment_Methods__c = 'Credit Card;Bank Account',
            ChargentBase__Bank_Account_Type__c = 'EFT (ACSS) - Canada',
            ChargentBase__Credit_Card_Data_Handling__c = 'Clear When Token Present',
            ChargentBase__Debug__c = false,
            ChargentBase__Enable_Refund__c = false,
            ChargentBase__Ezidebit_Pass_Fees_to_Payer__c = false,
            ChargentBase__Ignore_AVS_check__c = false,
            ChargentBase__Inherit_Chargent_Currency__c = false,
            ChargentBase__Micro_Deposits_Disabled__c = false,
            ChargentBase__Omit_CC_expiry__c = false,
            ChargentBase__PayFlow_Use_Recurring_Profiles__c = false,
            ChargentBase__Require_AVS__c = false,
            ChargentBase__Require_CCV__c = false,
            ChargentBase__Require_CVV__c = false,
            ChargentBase__SCA_enabled__c = false,
            ChargentBase__Show_Authorize_Button__c = false,
            ChargentBase__Show_Charge_Button__c = true,
            ChargentBase__Show_Create_Update_Token_Button__c = true,
            ChargentBase__Show_Setup_Recurring_Button__c = true,
            ChargentBase__Test_Mode__c = true,
            ChargentBase__Use_Reference_Transactions__c = false,
            ChargentBase__Use_Tokenization__c = true,
            Name = gatewayName
        );
        insert g;
        return g;
    }
}