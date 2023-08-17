trigger IsIDUniqueUnderTheAppeal on Package__c (before insert, before update) {
    Set<Id> AppealSet = new Set<Id>();
    
    for (Package__c Pack: Trigger.new) {
        if (Pack.Campaign_Appeal__c!=null) {
            AppealSet.add(Pack.Campaign_Appeal__c);
        }    
    }
    if (!AppealSet.isEmpty()) {
        List<Campaign> LCamp= [SELECT id, (SELECT Package_ID__c FROM Packages__r) FROM Campaign WHERE Id IN: AppealSet];
         
        for(Package__c Pack: Trigger.new) {
            for (Campaign Camp: LCamp) {
                if (Camp.Id==Pack.Campaign_Appeal__c) {
                    for (Package__c Pa: Camp.Packages__r) {
                        if (Pa.Package_ID__c==Pack.Package_ID__c) {
                            Pack.Package_ID__c.addError('Package with same Package ID already exists under current Appeal!');
                            break;
                        }
                    }    
                    break;
                }
            }
        }
    }
}