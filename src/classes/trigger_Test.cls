@isTest(SeeAllData=false)
private class trigger_Test 
{
    @isTest static void testTriggerDomain()
    {
        test_Data data = new test_Data();

        Test.startTest();

        trigger_Domain domain = new trigger_Domain();
        List<Task> tasks = new List<Task>{ data.task1a, data.task1b, data.task1c };
        Map<Id, Task> tasksMap = new Map<Id, Task>(tasks);

        domain.beforeInsert(tasks);
        domain.beforeInsert(tasksMap);
        domain.beforeUpdate(tasks, tasks);
        domain.beforeUpdate(tasksMap, tasksMap);
        domain.beforeDelete(tasks);
        domain.beforeDelete(tasksMap);

        domain.afterInsert(tasks);
        domain.afterInsert(tasksMap);
        domain.afterUpdate(tasks, tasks);
        domain.afterUpdate(tasksMap, tasksMap);
        domain.afterDelete(tasks);
        domain.afterDelete(tasksMap);

        update tasks;
        delete tasks;

        Test.stopTest();
    }

    @isTest static void testTriggerController()
    {
        test_Data data = new test_Data();

        Test.startTest();

        List<Task> tasks = new List<Task>{ data.task1a, data.task1b, data.task1c };

        System.debug('### TASKS: ' + tasks);

        update tasks;
        delete tasks;

        Test.stopTest();
    }

    @isTest static void testTriggerBatch()
    {
        trigger_TestData data = new trigger_TestData();

        Test.startTest();

        data.batch1.ESi_CL_Control_Batch_Processed__c = true;
        update data.batch1;

        Test.stopTest();
    }
}