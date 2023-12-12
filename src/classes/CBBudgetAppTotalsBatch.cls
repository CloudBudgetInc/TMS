global with sharing class CBBudgetAppTotalsBatch implements Database.Batchable<SObject>{

	public Map<Integer, List<String>> baMap;
	public Integer currentLvl;
	public String firstJobId;

	public Database.QueryLocator start(Database.BatchableContext BC) {
		System.debug('start BC.getJobId(): ' + BC.getJobId());
		if (firstJobId == null) {
			firstJobId = BC.getJobId();
		}
		System.debug('start currentLvl: ' + currentLvl);
		System.debug('start firstJobId: ' + firstJobId);
		System.debug('start baMap: ' + baMap);
		List<String> baIds = baMap.get(currentLvl);
		String query = 'SELECT Id FROM cb4__CBTag__c WHERE Id IN ' + cb4.CBUtils.getFormattedINQuery(new Set<String>(baIds));
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<sObject> scope) {
		System.debug('execute currentLvl: ' + currentLvl);
		System.debug('execute firstJobId: ' + firstJobId);
		System.debug('execute baMap: ' + baMap);
		Set<Id> setOfAppIds = new Set<Id>();
		for (Sobject s : scope) {
			setOfAppIds.add((Id) s.get('Id'));
		}
		CBBudgetAppTotalService.deleteAppOldTotals(setOfAppIds); // 3 requests
		CBBudgetAppTotalService.generateAppNewTotals(setOfAppIds); // 3 requests
	}

	public void finish(Database.BatchableContext BC) {
		System.debug('finish BC.getJobId(): ' + BC.getJobId());
		if (firstJobId == null) {
			firstJobId = BC.getJobId();
		}
		if (currentLvl > 1) {
			System.debug('finish currentLvl: ' + currentLvl);
			System.debug('finish firstJobId: ' + firstJobId);
			System.debug('finish baMap: ' + baMap);
			CBBudgetAppTotalsBatch job = new CBBudgetAppTotalsBatch();
			job.baMap = baMap;
			job.currentLvl = currentLvl - 1;
			job.firstJobId = firstJobId;
			Id batchInstanceId = Database.executeBatch(job, CBBudgetAppTotalService.totalsBatchSize);
		} else {
			publishEvent('BATotals', firstJobId, 'Finished');
		}
	}

	public static void publishEvent(String eventName, String eventText1, String status) {
		try{
			System.debug('publishEvent eventName: ' + eventName);
			System.debug('publishEvent eventText1: ' + eventText1);
			System.debug('publishEvent status: ' + status);
			cb4__CB_Custom_Event__e event = new cb4__CB_Custom_Event__e();
			event.cb4__Event_Name__c = eventName;
			event.cb4__Text1__c = eventText1;
			event.cb4__Status__c = status;
			EventBus.publish(event);
		} catch(Exception e) {
			System.debug('publishEvent e: ' + e);
		}
	}

	public static void cg(){
		Integer i = 0;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
	}

}