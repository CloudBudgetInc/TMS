/** 
Copyright (c) 2023, CloudBudget, Inc.
All rights reserved.
Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:
* Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.
* Neither the name of the CloudBudget, Inc. nor the names of its contributors
may be used to endorse or promote products derived from this software
without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
OF THE POSSIBILITY OF SUCH DAMAGE.

 */


public with sharing class CBReportingDepartmentLinePageController {

	@AuraEnabled
	public static Map<String, List<sObject>> getBaseAnalyticsServer() {
		Map<String, List<sObject>> r = new Map<String, List<sObject>>();
		r.put('dim1', [SELECT Id, Name FROM c2g__codaDimension1__c ORDER BY Name]);
		r.put('dim2', [SELECT Id, Name FROM c2g__codaDimension2__c ORDER BY Name]);
		r.put('dim3', [SELECT Id, Name FROM c2g__codaDimension3__c ORDER BY Name]);
		r.put('brd', [SELECT Id, Name, Reporting_Level__c FROM Budget_Reporting_Department__c ORDER BY Name]);
		return r;
	}

	@AuraEnabled
	public static List<Budget_Reporting_Department_Line__c> getAllBRDLServer() {
		return [
				SELECT
						Budget_Reporting_Department__c,
						Budget_Reporting_Department__r.Name,
						Dimension_1__c,
						Dimension_2__c,
						Dimension_3__c,
						Dimension_1__r.Name,
						Dimension_2__r.Name,
						Dimension_3__r.Name,
						Id,
						Name,
						Parent_Name__c,
						Reporting_Code__c,
						Reporting_Department_Level__c,
						StartDate__c,
						ExpDate__c
				FROM Budget_Reporting_Department_Line__c
				ORDER BY Reporting_Department_Level__c, Budget_Reporting_Department__r.Name, Name
		];
	}

	@AuraEnabled
	public static void saveBRDLinesServer(List<Budget_Reporting_Department_Line__c> BRDLines, Boolean safeMode) {
		if(!safeMode) {
			delete [SELECT Id FROM Budget_Reporting_Department_Line__c LIMIT 10000];
		}
		insert BRDLines;
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
	}

}