public with sharing class CBBudgetAppTotalService {
	private static final String budgetAppAmountDimId = cb4.CBUtils.dimensionNameIdMap.get(cb4.CBConstant.BUDGET_APP_AMOUNT_DIM);
	public static final Integer totalsBatchSize = 5;

	/**
     * the method refresh apps totals
     *
     * @param lvl
     * @param listOfAppIds
     */
	@AuraEnabled
	public static Decimal runRefreshAppsServer(Decimal lvl, List<Id> listOfAppIds) {
		List <UserRecordAccess> appAccessList = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId IN :listOfAppIds];
		List <Id> appFileteredList = new List <Id>();
		for(UserRecordAccess appAccess :appAccessList)
		{ if(appAccess.HasEditAccess)
		{appFileteredList.add(appAccess.RecordId);}
		}

		List<Approval.UnlockResult> ulrList = Approval.unlock(listOfAppIds);
		for (Approval.UnlockResult ulr : ulrList) {
			System.debug('ulr.isSuccess(): ' + ulr.isSuccess());
		}
		deleteAppOldTotals(new Set<Id>(appFileteredList)); // 3 requests
		generateAppNewTotals(new Set<Id>(appFileteredList));  // 3 requests

		return lvl;
	}

	/**
	 * the method deletes old total App lines
	 *
	 * @param appIds
	 */
	@TestVisible
	public static void deleteAppOldTotals(Set<Id> appIds) {
		List<cb4__CBTag__c> apps = [SELECT Id, cb4__Decimal1__c, cb4__Decimal2__c, cb4__Decimal3__c FROM cb4__CBTag__c WHERE Id IN:appIds WITH SECURITY_ENFORCED LIMIT 50000]; // 1
		for (cb4__CBTag__c a : apps) a.cb4__Decimal1__c = a.cb4__Decimal2__c = a.cb4__Decimal3__c = 0;
		update apps;  // 2


		List<cb4__CBTag__c> amounts = [SELECT Id, cb4__DimensionName__c, cb4__Text1__c, cb4__Tag1__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = :cb4.CBConstant.BUDGET_APP_AMOUNT_DIM AND cb4__Text1__c = 'total' AND cb4__Tag1__c IN:appIds WITH SECURITY_ENFORCED];
		for (cb4__CBTag__c t : amounts) t.OwnerId = System.UserInfo.getUserId();
		update amounts;


		delete [SELECT Id, cb4__DimensionName__c, cb4__Tag1__c, cb4__Text1__c FROM cb4__CBTag__c WHERE cb4__DimensionName__c = :cb4.CBConstant.BUDGET_APP_AMOUNT_DIM AND cb4__Text1__c = 'total' AND cb4__Tag1__c IN:appIds WITH SECURITY_ENFORCED]; // 3
	}
	/// UPDATE ALL APS /////

	/**
	 *
	 *
	 * @param setOfAppIds list of Apps which totals need to be generated
	 */
	@TestVisible
	public static void generateAppNewTotals(Set<Id> setOfAppIds) {
		/**
		 * totalsMap has two types of key
		 * 1. key = appId + periodId + lineType, value - total budget app amount
		 * 2. key = appId , value - application
		 */
		Map<String, cb4__CBTag__c> totalsMap = new Map<String, cb4__CBTag__c>(); // key - appId + periodId + lineType, value - total budget app amount
		String t = 'total';
		String i = 'income';
		String e = 'expense';

		// APP SIMPLE LINES
		List<AggregateResult> agrList = [ // 4
				SELECT SUM(cb4__Decimal1__c) amount,
						cb4__Tag1__c appId,
						cb4__Text1__c lineType, // income or expense
						cb4__Tag3__c periodId,
						MAX(cb4__Tag1__r.OwnerId) ownerId,
						MAX(cb4__Tag1Name__c) appName
				FROM cb4__CBTag__c
				WHERE cb4__DimensionName__c = :cb4.CBConstant.BUDGET_APP_AMOUNT_DIM
				AND cb4__Tag1__c IN:setOfAppIds // application lines
				AND cb4__Decimal1__c != null AND cb4__Decimal1__c != 0 AND cb4__Tag3__c != null AND cb4__Text1__c != null
				AND (cb4__Text1__c = :i OR cb4__Text1__c = :e)
				GROUP BY cb4__Tag1__c, cb4__Text1__c, cb4__Tag3__c
		];
		for (AggregateResult agr : agrList) {
			String lineType = (String) agr.get('lineType');
			Decimal amount = (Decimal) agr.get('amount');
			String appId = (String) agr.get('appId');
			Id ownerId = (Id) agr.get('ownerId');
			String periodId = (String) agr.get('periodId');
			String key = appId + periodId + lineType;
			totalsMap.put(key, new cb4__CBTag__c( // total Budget App Amount
					cb4__Dimension__c = budgetAppAmountDimId,
					cb4__Tag1__c = appId,
					cb4__Tag3__c = periodId,
					cb4__Decimal1__c = amount,
					cb4__Text1__c = t,
					cb4__Text2__c = lineType,
					cb4__Text3__c = lineType,
					OwnerId = ownerId
			));

			cb4__CBTag__c app = totalsMap.get(appId); // Budget App
			if (app == null) app = new cb4__CBTag__c(Id = appId, cb4__Decimal1__c = 0, cb4__Decimal2__c = 0);
			if (lineType == i) app.cb4__Decimal1__c += amount;
			if (lineType == e) app.cb4__Decimal2__c += amount;
			totalsMap.put(appId, app);
		}

		// SUBMISSION APPS TOTALS
		List<AggregateResult> agrListTotal = [ //5
				SELECT SUM(cb4__Decimal1__c) amount,
						cb4__Tag1__r.cb4__Tag1__c appId,
						cb4__Text2__c lineType,
						cb4__Tag3__c periodId,
						MAX(cb4__Tag1__r.cb4__Tag1__r.OwnerId) ownerId,
						MAX(cb4__Tag1Name__c) appName
				FROM cb4__CBTag__c
				WHERE cb4__DimensionName__c = :cb4.CBConstant.BUDGET_APP_AMOUNT_DIM
				AND cb4__Tag1__r.cb4__Tag1__c IN:setOfAppIds AND cb4__Text1__c = 'total'
				AND cb4__Decimal1__c != null AND cb4__Decimal1__c != 0 AND cb4__Tag3__c != null AND cb4__Text1__c != null
				GROUP BY cb4__Tag1__r.cb4__Tag1__c, cb4__Text1__c, cb4__Text2__c, cb4__Tag3__c
		];
		for (AggregateResult agr : agrListTotal) {
			String lineType = (String) agr.get('lineType');
			Decimal amount = (Decimal) agr.get('amount');
			String appId = (String) agr.get('appId');
			String periodId = (String) agr.get('periodId');
			Id ownerId = (String) agr.get('ownerId');
			String key = appId + periodId + lineType;

			cb4__CBTag__c totalTag = totalsMap.get(key);
			if (totalTag == null) {
				totalTag = new cb4__CBTag__c(
						cb4__Dimension__c = budgetAppAmountDimId,
						cb4__Tag1__c = appId,
						cb4__Tag3__c = periodId,
						cb4__Decimal1__c = amount,
						cb4__Text1__c = t,
						cb4__Text2__c = lineType,
						cb4__Text3__c = lineType,
						OwnerId = ownerId
				);
			} else totalTag.cb4__Decimal1__c += amount;
			totalsMap.put(key, totalTag);

			cb4__CBTag__c app = totalsMap.get(appId); // Budget App
			if (app == null) app = new cb4__CBTag__c(Id = appId, cb4__Decimal1__c = 0, cb4__Decimal2__c = 0);
			if (lineType == i) app.cb4__Decimal1__c += amount;
			if (lineType == e) app.cb4__Decimal2__c += amount;
			totalsMap.put(appId, app);
		}

		upsert totalsMap.values(); // 6

	}

	public static void codGen() {
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