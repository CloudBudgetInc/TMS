/**
 * Created by Alex JR on 21/08/19.
 */
({
	doInit: function (cmp, event, helper) {
		_showSpinner(cmp);
		document.title = _TEXT.APP_SHEET.MODULE_HEADER;
		const recordId = cmp.get("v.recordId");
		_cl("APP ID=" + recordId, 'orange');

		helper.helpGetGroupFilterSO(cmp);
		helper.helpGetAllApps(cmp);
		helper.helpGetRootApp(cmp);
		helper.helpGetTableHeaders(cmp);
		helper.helpGetAllAccountsAndDimension(cmp);
		helper.helpGetAdditionalReferences(cmp);
	},

	refreshData: function (cmp, event, helper) {
		_showSpinner(cmp);
		window.setTimeout(
			$A.getCallback(function () {
				helper.helpRefreshData(cmp);
			}), 10
		);

	},

	redirectToBudgetApp: function (cmp, event, helper) {
		let appId = cmp.get("v.app.Id");
		function redirect(cmp, response) {
			const cmpName = response.getReturnValue();
			let param = {
				recordId : appId
			};
			_CBRedirect.toComponent(cmpName, param);
		}
		_CBRequest(
			cmp,
			"c.getProperlyCmpNameServer",
			{
				"recordId": appId,
				"dimensionId": null,
				"createNewTag": false
			},
			null,
			redirect,
			null,
			'Redirect Error'
		);
	},

	/////// EXCEL


	showExcelPanel: function (cmp, event, helper) {
		helper.helpShowExcelPanel();
	},
	downloadExcelConsolidated: function (cmp, event, helper) {
		helper.helpDownloadExcelConsolidated(cmp);
		helper.helpShowExcelPanel();
	},
	downloadExcelSplitBySheets: function (cmp, event, helper) {
		helper.helpDownloadExcelSplitBySheets(cmp);
		helper.helpShowExcelPanel();
	},
	backToMainTable: function (cmp, event, helper) {
		helper.helpBackToMainTable(cmp);
	}
});