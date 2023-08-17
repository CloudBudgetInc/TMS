@isTest
private class TriggerHandler_Test {

    @isTest static void test_method_one() {
        Trigger_Framework_Settings__c dsTriggers = new Trigger_Framework_Settings__c();
        dsTriggers.Name = 'test';
        insert dsTriggers; 
        dsTriggers.Name = 'test updated';
        update dsTriggers;
        delete dsTriggers;
        Database.undelete(dsTriggers.Id);
    }
    @isTest static void test_method_two() { 
        try {
        	TriggerHandler handler = new TriggerHandler();
        	handler.run();
        }catch(exception Ex){}
    }
    @isTest static void test_method_three() {        
        TriggerHandler.AddProcessRun('test', '003o0000005C74S');
        system.assert(TriggerHandler.DidProcessRan('test', '003o0000005C74S'));
        TriggerHandler.bypass('Test');
        system.assert(TriggerHandler.isBypassed('Test'));
        TriggerHandler.clearBypass('Test');
        TriggerHandler.clearAllBypasses();
    }
    @isTest static void test_method_four() {
        Trigger_Framework_Settings__c dsTriggers = new Trigger_Framework_Settings__c();
        dsTriggers.Name = 'Setting';
        dsTriggers.Disabled_Triggers__c = 'FrameworkTriggerHandler';
        dsTriggers.Disable_All_Triggers__c = true;
        insert dsTriggers; 
        test.startTest();
        TriggerHandler.loadSettings();
        dsTriggers.Name = 'FrameworkTriggerHandler';
        update dsTriggers;
        test.stopTest();
        
    }
}