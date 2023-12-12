/**
 * Created by Alex JR on 27/9/2023.
 */

public with sharing class CBServiceV2 {

	private static final Id BRD_DIM_ID = cb4.CBUtils.dimensionNameIdMap.get('Budget Reporting Department');
	private static final Id BASE_SCENARIO_ID = [SELECT Id FROM cb4__CBTag__c WHERE cb4__Dimension__c = :cb4.CBUtils.dimensionNameIdMap.get('Scenario') AND Name = 'Base' LIMIT 1][0].Id;

	public static List<Budget_Reporting_Department_Line__c> getBudgetReportingLines() {
		return [
				SELECT Id,
						Name,
						Budget_Reporting_Department__c,
						Budget_Reporting_Department__r.Reporting_Level__c,
						Budget_Reporting_Department__r.Name,
						Dimension_1__c,
						Dimension_2__c,
						Dimension_3__c,
						Dimension_1__r.Name,
						Dimension_2__r.Name,
						Dimension_3__r.Name,
						Parent_Name__c,
						Reporting_Code__c,
						Reporting_Department_Level__c
				FROM Budget_Reporting_Department_Line__c
				ORDER BY Budget_Reporting_Department__r.Reporting_Level__c
				LIMIT 50000
		];
	}

	public static List<cb4.CBSO> getYearsSO() {
		List<cb4.CBSO> years = new List<cb4.CBSO>();
		for (cb4__CBTag__c a : [SELECT Name FROM cb4__CBTag__c WHERE cb4__Dimension__c = :cb4.CBUtils.dimensionNameIdMap.get('Budget Year') ORDER BY Name LIMIT 50000]) years.add(new cb4.CBSO(a.Name, a.Name));
		return years;
	}

	public static List<cb4.CBSO> getBaseYearsSO() {
		List<cb4.CBSO> years = new List<cb4.CBSO>();
		List<Id> yearsWithApprove = new List<Id>();
		for (SObject app : [SELECT cb4__Tag3__c FROM cb4__CBTag__c WHERE cb4__Dimension__c = :cb4.CBUtils.dimensionNameIdMap.get('Budget App') AND cb4__Tag8__c = :BASE_SCENARIO_ID AND cb4__Status__c != 'Open' GROUP BY cb4__Tag3__c LIMIT 50000]) {
			yearsWithApprove.add((Id) app.get('cb4__Tag3__c'));
		}
		for (cb4__CBTag__c a : [SELECT Name FROM cb4__CBTag__c WHERE cb4__Dimension__c = :cb4.CBUtils.dimensionNameIdMap.get('Budget Year') AND Id NOT IN :yearsWithApprove ORDER BY Name LIMIT 50000]) years.add(new cb4.CBSO(a.Name, a.Name));
		return years;
	}

	public static List<cb4.CBSO> getPeriodsSO() {
		List<cb4.CBSO> periods = new List<cb4.CBSO>();
		for (cb4__CBTag__c a : [SELECT Name FROM cb4__CBTag__c WHERE cb4__Dimension__c = :cb4.CBUtils.dimensionNameIdMap.get('Period') AND cb4__Start__c >= :CBVariable.startFY AND cb4__End__c <= :CBVariable.endFY ORDER BY cb4__Start__c ASC LIMIT 50000]) periods.add(new cb4.CBSO(a.Name, a.Name));
		return periods;
	}

	/**
	 * Service method uses TMS Budget_Reporting_Department_Line__c mapping rules
	 * key is * CB2 Dim1 ID + Dim2 Id + Dim3 Id (CloudBudget Dimension 1,2,3)
	 * value is CB Budget Reporting Department of needed level
	 * @param lvl reporting LVL (1 || 2 || 3)
	 *
	 * @return
	 */
	public static Map<String, String> getBridgeDim1Dim2Dim3Map(Integer lvl) {
		String lvlText = 'Level ' + lvl;
		Map<String, String> r = new Map<String, String>();
		Date startBYDate = CBVariable.startFY;
		Date endBYDate = CBVariable.endFY;

		Map<String, String> dimAndBRDBridge = new Map<String, String>(); // mapping of CB Dimensions and RBs. Key is FF record Id, value is CB analogue
		for (cb4__CBTag__c t : [
				SELECT Id, cb4__ExtId__c
				FROM cb4__CBTag__c
				WHERE (cb4__Dimension__c = :BRD_DIM_ID
				OR cb4__Dimension__c = :cb4.CBUtils.dimensionNameIdMap.get('CB_FF1') // CB_FF1 dimension Id
				OR cb4__Dimension__c = :cb4.CBUtils.dimensionNameIdMap.get('CB_FF2')
				OR cb4__Dimension__c = :cb4.CBUtils.dimensionNameIdMap.get('CB_FF3')
				)
				AND cb4__ExtId__c != null
				LIMIT 50000
		]) dimAndBRDBridge.put(t.cb4__ExtId__c, t.Id);

		for (List<Budget_Reporting_Department_Line__c> brdls : [ // MuSeed custom sObjects
				SELECT Dimension_1__c, Dimension_2__c, Dimension_3__c, Budget_Reporting_Department__c
				FROM Budget_Reporting_Department_Line__c
				WHERE Budget_Reporting_Department__r.Reporting_Level__c = :lvlText // number of BRD level
				AND ((StartDate__c = NULL OR StartDate__c >= :startBYDate) AND (ExpDate__c <= :endBYDate OR ExpDate__c = NULL))
				LIMIT 50000
		]) {
			for (Budget_Reporting_Department_Line__c brdl : brdls) {
				String dim1 = brdl.Dimension_1__c == null ? null : dimAndBRDBridge.get(brdl.Dimension_1__c);
				String dim2 = brdl.Dimension_2__c == null ? null : dimAndBRDBridge.get(brdl.Dimension_2__c);
				String dim3 = brdl.Dimension_3__c == null ? null : dimAndBRDBridge.get(brdl.Dimension_3__c);
				String CB2BRD = dimAndBRDBridge.get(brdl.Budget_Reporting_Department__c);
				r.put(dim1 + dim2 + dim3, CB2BRD);
			}
		}
		return r;
	}

	 /**
	 * Each BDG has an owner Id
	 *
	 * @return map where key is CB BDG Id, value is respective User Id
	 */
	public static Map<String, String> getBDGToOwnerMap() {
		Map<String, String> r = new Map<String, String>();
		for (cb4__CBTag__c bdg : [SELECT Id, OwnerId FROM cb4__CBTag__c WHERE cb4__Dimension__c = :cb4.CBUtils.dimensionNameIdMap.get('BDG') LIMIT 5000]) r.put(bdg.Id, bdg.OwnerId);
		return r;
	}

}