/**
 * Created by Alex JR on 10/9/2020.
 */

public with sharing class CBBudgetAppTitleConverter implements Database.Batchable<SObject> {

    private static final String spaces = '     ';

    public Database.QueryLocator start(Database.BatchableContext context) {
        String q = 'SELECT cb4__Text3__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = \'Budget App Amount\' AND cb4__Text3__c LIKE \'%     %\'';
        return Database.getQueryLocator(q);
    }

    public void execute(Database.BatchableContext context, List<cb4__CBTag__c> scope) {
        for(cb4__CBTag__c t : scope) {
            List<String> tmp = t.cb4__Text3__c.split(spaces);
            t.cb4__Text3__c = tmp[1] + spaces + tmp[0];
        }
        update scope;
    }

    public void finish(Database.BatchableContext context) {

    }

}