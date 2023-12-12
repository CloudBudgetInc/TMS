({
	constants: {
		'income': 1,
		'expense': 2
	},
	helpGetAppList: function (cmp) {
		let action = cmp.get("c.getBudgetAppsServer");
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let result = response.getReturnValue();
				cmp.set("v.apps", result);
				this.helpGenerateMainStructure(cmp);
			} else {
				_RequestError(response, "helpGetAppList ", cmp);
			}
			_hideSpinner(cmp);
		});
		$A.enqueueAction(action);
	},

	helpGetBudgetAppDimension: function (cmp) {
		function callback(cmp, res){
			let dimension = res.getReturnValue();
			let configMap = {};
			for(let key in dimension){
				if(dimension.hasOwnProperty(key)) {
					try {
						configMap[key] = JSON.parse(dimension[key]);
					}catch (e){
						configMap[key] = dimension[key];
					}
				}
			}
			cmp.set('v.appDimension', configMap);
		}
		_CBRequest(cmp, "c.getBudgetAppDimensionServer", null, null, callback, null, 'Failed', false);
	},

	helpGetBudgetAppAmountDimension: function (cmp) {
		function callback(cmp, res){
			let dimension = res.getReturnValue();
			let configMap = {};
			for(let key in dimension){
				if(dimension.hasOwnProperty(key)) {
					try {
						configMap[key] = JSON.parse(dimension[key]);
					}catch (e){
						configMap[key] = dimension[key];
					}
				}
			}
			cmp.set('v.amountDimension', configMap);
		}
		_CBRequest(cmp, "c.getBudgetAppAmountDimensionServer", null, null, callback, null, 'Failed', false);
	},

	/**
	 * Creating a new App
	 */
	helpCreateApp: function (cmp) {
		_showSpinner(cmp);
		this.helpGetNeededSO(cmp);
		let action = cmp.get("c.getNewBudgetAppServer");
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let newApp = response.getReturnValue();
				_cl('NEW BUDGET:' + JSON.stringify(newApp), 'yellow');
				newApp.Name = 'New App';
				cmp.set("v.app", newApp);
				cmp.set("v.mode", 'single');
				this.helpEraseOldAppData(cmp);
				this.enableButtonSave(cmp);
			} else {
				_RequestError(response, _TEXT.APPS.FAILED_GET_NEW_APP, cmp);
			}
			_hideSpinner(cmp);
		});
		$A.enqueueAction(action);
	},

	helpGetApp: function (cmp, appOnly) {
		let _this = this;
		_showSpinner(cmp);
		cmp.set("v.needSave", false);
		let action = cmp.get("c.getBudgetAppsServer");
		action.setParams({
			"appId": cmp.get("v.app.Id")
		});
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let apps = response.getReturnValue();
				_cl('apps' + JSON.stringify(apps));
				cmp.set("v.app", apps[0]);
				_this.helpSetBackup(cmp, 'Budget App opened');
				_this.getAttachedDocuments(cmp);
				cmp.set("v.headerTitle", '');
				document.title = apps[0].cb4__TagLabel__c;
				_this.helpSetEditDisabledVariable(cmp, cmp.get('v.app'));
				if (appOnly === 'true') return null;
			} else {
				_RequestError(response, _TEXT.APPS.FAILED_GET_APP, cmp);
			}
		});
		$A.enqueueAction(action);
	},

	helpSetEditDisabledVariable: function(cmp, app) {
		let _this = this;
		if(app.cb4__Status__c !== 'Open'){
			cmp.set("v.editDisabled", true);
		}else{
			function callback(cmp, res){
				if(res.getReturnValue()){
					_this.disableButtonSave(cmp);
				}
			}
			_CBRequest(
				cmp,
				'c.isUserHasAccessToEditBudgetServer',
				{ appId : app.Id },
				'v.editDisabled',
				callback,
				null,
				null,
				false
			);
		}
	},

	helpGetTemplate: function (cmp) {
		let action = cmp.get("c.getBudgetTemplateServer");
		action.setParams({
			"appId": cmp.get("v.app.Id")
		});
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let template = response.getReturnValue();
				if (_isInvalid(template.Id)) _CBMessages.fireErrorMessage(_TEXT.APPS.NO_TEMPLATE);
				cmp.set("v.template", template);
			} else {
				_RequestError(response, _TEXT.APPS.FAILED_GET_TEMPLATE, cmp);
			}
		});
		$A.enqueueAction(action);
	},
	/**
	 * The method received a list of table headers
	 */
	helpGetTableHeaders: function (cmp) {
		_CBRequest(cmp, "c.getTableHeadersServer", {"appId": cmp.get("v.app.Id")}, "v.headers", null, null, _TEXT.APPS.FAILED_GET_HEADERS, false);
		_CBRequest(cmp, "c.getAppPeriodsServer", {"appId": cmp.get("v.app.Id")}, "v.periods", null, null, _TEXT.APPS.FAILED_GET_HEADERS, false);
	},
	helpGetTotalData: function (cmp) {
		let action = cmp.get("c.getRowsServer");
		action.setParams({
			"appId": cmp.get("v.app.Id"),
			"type": "total"
		});
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let totalRows = response.getReturnValue();
				_cl('totalRows: ' + JSON.stringify(totalRows), 'purple');
				totalRows = this.arrayToObjects(totalRows, cmp);
				totalRows = this.helpSetDisableInputs(totalRows);
				if (!this.showIncomePart(cmp)) totalRows[0].class = 'truehide'; // show only income if needed
				if (!this.showExpensePart(cmp)) totalRows[1].class = 'truehide'; // show only expense if needed
				if (totalRows.length > 0) cmp.set("v.totalData", totalRows); else cmp.set("v.totalData", []);
			} else {
				let errors = response.getError();
				if (errors) {
					if (errors[0] && errors[0].message) _CBMessages.fireErrorMessage(_TEXT.APPS.FAILED_GET_TOTAL + errors[0].exceptionType + '. ' + errors[0].stackTrace);
				} else {
					_RequestError(response, _TEXT.APPS.FAILED_GET_TOTAL, cmp);
				}
			}
		});
		$A.enqueueAction(action);
	},

	helpGetTargetTotalData: function (cmp) {
		let action = cmp.get("c.getRowsServer");
		action.setParams({
			"appId": cmp.get("v.app.Id"),
			"type": "targetTotal"
		});
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (state === "SUCCESS") {

				let targetTotalRows = response.getReturnValue();
				_cl('targetTotalRows: ' + JSON.stringify(targetTotalRows), 'blue');
				targetTotalRows = this.arrayToObjects(targetTotalRows, cmp);
				targetTotalRows = this.helpSetDisableInputs(targetTotalRows);
				targetTotalRows[0].title = 'BUDGETED INCOME';
				targetTotalRows[1].title = 'BUDGETED EXPENSES';
				let remainingIncome = JSON.parse(JSON.stringify(targetTotalRows[0]));
				let remainingBTDIncome = JSON.parse(JSON.stringify(targetTotalRows[0]));
				let remainingExpense = JSON.parse(JSON.stringify(targetTotalRows[1]));
				let remainingBTDExpense = JSON.parse(JSON.stringify(targetTotalRows[1]));
				remainingIncome.title = 'REMAINING INCOME';
				remainingBTDIncome.title = 'REMAINING INCOME YTD';
				remainingExpense.title = 'REMAINING EXPENSES';
				remainingBTDExpense.title = 'REMAINING EXPENSES YTD';

				let r = [targetTotalRows[0], remainingIncome, remainingBTDIncome, targetTotalRows[1], remainingExpense, remainingBTDExpense];

				if (!this.showIncomePart(cmp)) {
					r[0].class = 'truehide';
					r[1].class = 'truehide';
					r[2].class = 'truehide';
				}
				if (!this.showExpensePart(cmp)) {
					r[3].class = 'truehide';
					r[4].class = 'truehide';
					r[5].class = 'truehide';
				}
				if (targetTotalRows.length > 0) cmp.set("v.targetTotalData", r); else cmp.set("v.targetTotalData", []);
			} else {
				_CBMessages.fireErrorMessage('TARGET TOTALS');
			}
		});
		$A.enqueueAction(action);
	}
	,

	helpGetIncomeData: function (cmp) {
		let action = cmp.get("c.getRowsServer");
		let pageFilter = cmp.get("v.pageFilter");

		action.setParams({
			"appId": cmp.get("v.app.Id"),
			"type": "income",
			"addedWhere": pageFilter
		});
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let incomeRows = response.getReturnValue();
				_cl('incomeRows: ' + JSON.stringify(incomeRows), 'green');
				incomeRows = this.arrayToObjects(incomeRows, cmp);
				if (incomeRows.length > 0){
					let grantsMap = cmp.get('v.grantsMap');
					let income = [];
					let grantsObj = {};
					let grantIncome = [];

					for(let i = 0; i < incomeRows.length; i++){
						if(incomeRows[i].dim8 in grantsMap){
							if(grantsMap[incomeRows[i].dim8] in grantsObj){
								grantsObj[grantsMap[incomeRows[i].dim8]].push(incomeRows[i]);
								for(let vi = 0; vi < grantsObj[grantsMap[incomeRows[i].dim8]][0].rowValues.length; vi++) {
									grantsObj[grantsMap[incomeRows[i].dim8]][0].rowValues[vi].v += parseFloat(incomeRows[i].rowValues[vi].v);
								}
							}else{
								let totalRow = JSON.parse(JSON.stringify(incomeRows[i]));
								totalRow.title = 'Total';
								totalRow.key = '';
								totalRow.styleClass = 'total';
								totalRow.description = 'Grant Total';
								for(let j = 0; j < totalRow.rowValues.length; j++){
									totalRow.rowValues[j].t = 'disabled';
								}
								grantsObj[grantsMap[incomeRows[i].dim8]] = [totalRow];
								grantsObj[grantsMap[incomeRows[i].dim8]].push(incomeRows[i]);
							}
						}else{
							income.push(incomeRows[i]);
						}
					}

					for(let key in grantsObj){
						grantIncome.push([key, grantsObj[key]]);
					}

					cmp.set("v.incomeData", income);
					cmp.set('v.grantIncomeData', grantIncome);
				}else{
					cmp.set("v.incomeData", []);
					cmp.set("v.grantIncomeData", []);
				}
			} else {
				_RequestError(response, _TEXT.APPS.FAILED_GET_INCOME, cmp);
			}
		});
		$A.enqueueAction(action);
	}
	,
	/**
	 * SUB INCOME
	 */
	helpGetDownUpSubIncomeData: function (cmp) {
		let action = cmp.get("c.getDownUpSubRowsServer");
		action.setParams({
			"appId": cmp.get("v.app.Id"),
			"type": "income"
		});
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let incomeSubRows = response.getReturnValue();
				incomeSubRows = this.arrayToObjects(incomeSubRows, cmp);

				try {
					cmp.set("v.incomeDownUpSubData", incomeSubRows);
				} catch (e) {

				}
			} else {
				_RequestError(response, _TEXT.APPS.FAILED_GET_SUB_INCOME, cmp);
			}
		});
		$A.enqueueAction(action);
	}
	,
	helpGetTopDownSubIncomeData: function (cmp) {
		let action = cmp.get("c.getTopDownSubRowsServer");
		action.setParams({
			"appId": cmp.get("v.app.Id"),
			"type": "income"
		});
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let incomeSubRows = response.getReturnValue();
				incomeSubRows = this.arrayToObjects(incomeSubRows, cmp);

				try {
					cmp.set("v.incomeTopDownSubData", incomeSubRows);
				} catch (e) {

				}
			} else {
				_RequestError(response, _TEXT.APPS.FAILED_GET_SUB_INCOME, cmp);
			}
		});
		$A.enqueueAction(action);
	}
	,
	helpGetExpenseData: function (cmp) {
		let action = cmp.get("c.getRowsServer");
		let pageFilter = cmp.get("v.pageFilter");
		action.setParams({
			"appId": cmp.get("v.app.Id"),
			"type": "expense",
			"addedWhere": pageFilter
		});
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				this.enableButtonSave(cmp);
				let expenseRows = response.getReturnValue();
				_cl('expenseRows: ' + JSON.stringify(expenseRows), 'yellow');
				expenseRows = this.arrayToObjects(expenseRows, cmp);
				if (expenseRows.length > 0){
					let grantsMap = cmp.get('v.grantsMap');
					let expenses = [];
					let grantsObj = {};
					let grantExpenses = [];

					for(let i = 0; i < expenseRows.length; i++){
						if(expenseRows[i].dim8 in grantsMap){
							if(grantsMap[expenseRows[i].dim8] in grantsObj){
								grantsObj[grantsMap[expenseRows[i].dim8]].push(expenseRows[i]);
								for(let vi = 0; vi < grantsObj[grantsMap[expenseRows[i].dim8]][0].rowValues.length; vi++) {
									grantsObj[grantsMap[expenseRows[i].dim8]][0].rowValues[vi].v += parseFloat(expenseRows[i].rowValues[vi].v);
								}
							}else{
								let totalRow = JSON.parse(JSON.stringify(expenseRows[i]));
								totalRow.title = 'Total';
								totalRow.key = '';
								totalRow.styleClass = 'total';
								totalRow.description = 'Grant Total';
								for(let j = 0; j < totalRow.rowValues.length; j++){
									totalRow.rowValues[j].t = 'disabled';
								}
								grantsObj[grantsMap[expenseRows[i].dim8]] = [totalRow];
								grantsObj[grantsMap[expenseRows[i].dim8]].push(expenseRows[i]);
							}
						}else{
							expenses.push(expenseRows[i]);
						}
					}

					for(let key in grantsObj){
						grantExpenses.push([key, grantsObj[key]]);

					}

					cmp.set("v.expenseData", expenses);
					cmp.set('v.grantExpenseData', grantExpenses);
				}else{
					cmp.set("v.expenseData", []);
					cmp.set("v.grantExpenseData", []);
				}
			} else {
				_RequestError(response, _TEXT.APPS.FAILED_GET_EXPENSE, cmp);
			}
		});
		$A.enqueueAction(action);
	}
	,
	/**
	 * SUB Down Up EXPENSE
	 */
	helpGetDownUpSubExpenseData: function (cmp) {
		let action = cmp.get("c.getDownUpSubRowsServer");
		action.setParams({
			"appId": cmp.get("v.app.Id"),
			"type": "expense"
		});
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let expenseSubRows = response.getReturnValue();
				expenseSubRows = this.arrayToObjects(expenseSubRows, cmp);

				try {
					cmp.set("v.expenseDownUpSubData", expenseSubRows);
				} catch (e) {

				}

				// Final preparation
				_hideSpinner(cmp);
				this.helpCalculateTotalRows(cmp, 'income');
				this.helpCalculateTotalRows(cmp, 'expense');
				this.helpCalculateMarginRow(cmp); // calculate margin / difference
				this.helpCalculateTargetTotalRows(cmp, 'income');
				this.helpCalculateTargetTotalRows(cmp, 'expense');
				this.helpTitleRows(cmp);
				this.helpGetAppNavigation(cmp);
				this.helpGetAdditionalAppComponent(cmp);
				this.helpGetAdditionalBudgetLineComponent(cmp);
			} else {
				_RequestError(response, _TEXT.APPS.FAILED_GET_SUB_INCOME, cmp);
			}
		});
		$A.enqueueAction(action);
	}
	,
	/**
	 * SUB Down Up EXPENSE
	 */
	helpGetTopDownSubExpenseData: function (cmp) {
		let action = cmp.get("c.getTopDownSubRowsServer");
		action.setParams({
			"appId": cmp.get("v.app.Id"),
			"type": "expense"
		});
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let expenseSubRows = response.getReturnValue();
				expenseSubRows = this.arrayToObjects(expenseSubRows, cmp);
				try {
					cmp.set("v.expenseTopDownSubData", expenseSubRows);
				} catch (e) {

				}

			} else {
				_RequestError(response, _TEXT.APPS.FAILED_GET_SUB_INCOME, cmp);
			}
		});
		$A.enqueueAction(action);
	}
	,
	helpGetAccounts: function (cmp) {
		let action = cmp.get("c.getAccountsServer");
		action.setParams({
			"appId": cmp.get("v.app.Id")
		});
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let acc = response.getReturnValue();
				cmp.set("v.incomeAccountsSO", acc['income']);
				cmp.set("v.expenseAccountsSO", acc['expense']);
				cmp.set("v.accountToSubtypeSO", acc['accountToSubtype']);
				cmp.set('v.accountsSO', acc['income'].concat(acc['expense']));
			} else {
				_RequestError(response, _TEXT.APPS.FAILED_ACCOUNTS, cmp);
			}
		});
		$A.enqueueAction(action);
	}
	,
	/**
	 * App dimensions and line dimensions
	 */
	helpGetNeededSO: function (cmp) {
		let action = cmp.get("c.getExtraDimensionsSOServer");
		action.setParams({
			"appId": cmp.get("v.app.Id")
		});
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let result = response.getReturnValue();
				_cl(result["d6"], 'red');
				_cl(result["d7"], 'red');
				_cl(cmp.get("v.app.Id"), 'red');
				try {
					for (let i = 4; i <= 10; i++) {

						// App line SO
						let dSO = result["d" + i];
						if (!_isInvalid(dSO)) {
							cmp.set("v.d" + i + "SO", JSON.parse(dSO));
							cmp.set("v.d" + i + "name", result["dname" + i]);
						}

						if (!_isInvalid(result["Text" + i + "__c"])) cmp.set("v.Text" + i + "__c", result["Text" + i + "__c"]);
						if (!_isInvalid(result["Decimal" + i + "__c"])) cmp.set("v.Decimal" + i + "__c", result["Decimal" + i + "__c"]);

						// App SO
						let appdSO = result["appd" + i];
						if (!_isInvalid(appdSO)) {
							cmp.set("v.appDim" + i + "SO", JSON.parse(appdSO));
							cmp.set("v.appDim" + i + "name", result["appdname" + i]);
						}
					}
					this.helpGetGenerateLinesByTypeSO(cmp);
				} catch (e) {
					alert(e);
				}
				this.helpGetMainAppSO(cmp);
			} else {
				_RequestError(response, "getExtraDimensionsSOServer Failed", cmp);
			}
		});
		$A.enqueueAction(action);
	}
	,

	helpEraseOldAppData: function (cmp) {
		for (let i = 0; i < 2; i++) {
			cmp.set("v.totalData", []);
			cmp.set("v.incomeData", []);
			cmp.set("v.incomeDownUpSubData", []);
			cmp.set("v.incomeTopDownSubData", []);
			cmp.set("v.expenseData", []);
			cmp.set("v.expenseDownUpSubData", []);
			cmp.set("v.expenseTopDownSubData", []);
			cmp.set("v.navigationStrings", []);
		}
	}
	,

	helpSaveApp: function (cmp, callBack) {
		console.clear();
		_showSpinner(cmp);
		let _this = this;

		let expenseData = cmp.get("v.expenseData");
		let incomeData = cmp.get("v.incomeData");

		let grantIncome = JSON.parse(JSON.stringify(cmp.get('v.grantIncomeData')));
		let grantExpense = JSON.parse(JSON.stringify(cmp.get('v.grantExpenseData')));

		for(let i = 0; i < grantIncome.length; i++){
			grantIncome[i][1].shift();
			incomeData = incomeData.concat(grantIncome[i][1]);
		}
		for(let i = 0; i < grantExpense.length; i++){
			grantExpense[i][1].shift();
			expenseData = expenseData.concat(grantExpense[i][1]);
		}

		try {
			/// VALIDATION
			let warning;
			if (cmp.get("v.app.Id") === undefined || cmp.get("v.app.Id") == null) { // initial validation
				warning = _this.helpValidateInitialSaving(cmp);
				if (warning !== null) {
					_CBMessages.fireErrorMessage(warning);
					_hideSpinner(cmp);
					return;
				}
			} else {
				let emptyLineWarning = 'Lines containing only 0 cannot be saved';
				let emptyInputWarning = 'Each input must have a number';
				let needAskForEmptyInput;
				for (let i = expenseData.length; i--;) {
					let needAskForEmptyLine = true;
					for (let j = 0; expenseData[i].rowValues.length - 1 > j; j++) {
						if (_isInvalidNumber(expenseData[i].rowValues[j].v)) {
							needAskForEmptyInput = " expense " + expenseData[i].title + "(" + (j + 1) + ") " + "*" + expenseData[i].rowValues[j].v + "*";
							break;
						}
						if (parseFloat(expenseData[i].rowValues[j].v) !== 0) needAskForEmptyLine = false;
					}
					if (needAskForEmptyLine) {
						_CBMessages.fireWarningMessage(emptyLineWarning);
						_hideSpinner(cmp);
						return null;
					}
				}
				for (let i = incomeData.length; i--;) {
					let needAskForEmptyLine = true;
					for (let j = 0; incomeData[i].rowValues.length - 1 > j; j++) {
						if (_isInvalidNumber(incomeData[i].rowValues[j].v)) {
							needAskForEmptyInput = " income " + incomeData[i].title + "(" + (j + 1) + ") " + "*" + incomeData[i].rowValues[j].v + "*";
						}
						if (parseFloat(incomeData[i].rowValues[j].v) !== 0) needAskForEmptyLine = false;
					}
					if (needAskForEmptyLine) {
						_CBMessages.fireWarningMessage(emptyLineWarning);
						_hideSpinner(cmp);
						return null;
					}
				}
				if (!_isInvalid(needAskForEmptyInput)) {
					_CBMessages.fireWarningMessage(emptyInputWarning);
					_cl("THE ISSUE IS IN THE INPUT FROM LINE: " + needAskForEmptyInput + " ", "orange");
					_hideSpinner(cmp);
					return null;
				}
			}
			/// VALIDATION

			cmp.set("v.needSave", false);

			let app = cmp.get("v.app");

			let expenses = JSON.parse(JSON.stringify(expenseData)); // clone expenses
			_this.objectsToArray(expenses);

			let income = JSON.parse(JSON.stringify(incomeData));
			_this.objectsToArray(income);

			_cleanObject(app);
			_cleanArray(income);
			_cleanArray(expenses);

			// App main totals calculation
			let totals = JSON.parse(JSON.stringify(cmp.get("v.totalData")));

			// remove margin from totals before saving
			let refineTotals = [];
			for (let k = 0; totals.length > k; k++) if (totals[k].ie !== 'margin') refineTotals.push(totals[k]);
			totals = refineTotals;

			if (totals.length > 0) { // if it's not initialization
				let totalIncome = totals[0].rowValues[totals[0].rowValues.length - 1];
				let totalExpense = totals[1].rowValues[totals[1].rowValues.length - 1];
				app.cb4__Decimal1__c = totalIncome.v;
				app.cb4__Decimal2__c = totalExpense.v;
			}

			// App main totals calculation
			_this.objectsToArray(totals);

			this.helpSetUniqueKeyBeforeSaving(expenses); // work around the duplicates
			this.helpSetUniqueKeyBeforeSaving(income);


			expenses = this.helpConvertRowsToCBTags(cmp, expenses, 'expense');
			income = this.helpConvertRowsToCBTags(cmp, income, 'income');
			totals = this.helpConvertRowsToCBTags(cmp, totals, 'total');


			app.cb4__Tag1__c = app.cb4__Tag1__c === undefined ? null : app.cb4__Tag1__c;
			app.cb4__Tag6__c = app.cb4__Tag6__c === undefined ? null : app.cb4__Tag6__c;
			app.cb4__Tag7__c = app.cb4__Tag7__c === undefined ? null : app.cb4__Tag7__c;
			app.cb4__Tag8__c = app.cb4__Tag8__c === undefined ? null : app.cb4__Tag8__c;
			app.cb4__Tag9__c = app.cb4__Tag9__c === undefined ? null : app.cb4__Tag9__c;
			app.cb4__Tag10__c = app.cb4__Tag10__c === undefined ? null : app.cb4__Tag10__c;
			app.cb4__Text3__c = app.cb4__Text3__c === undefined ? null : app.cb4__Text3__c;
			app.cb4__isLocked__c = app.cb4__isLocked__c === undefined || app.cb4__isLocked__c === null ? false : app.cb4__isLocked__c;

			let action = cmp.get("c.saveAppTagsServer");
			action.setParams({
				"app": app,
				"expenseTags": expenses,
				"incomeTags": income,
				"totalTags": totals
			});
			action.setCallback(_this, function (response) {
				let state = response.getState();
				if (state === "SUCCESS") {
					try {
						let appId = response.getReturnValue();
						if (cmp.get("v.app.Id") == null) {
							cmp.set("v.mode", 'table');
							_hideSpinner(cmp);
							_CBRedirect.toURL('/' + appId); // restart to the new App
							return null;
						}
						_this.helpGetApp(cmp, 'true');
						_this.helpGetTopDownSubExpenseData(cmp);
						_this.helpGetDownUpSubExpenseData(cmp);
						_hideSpinner(cmp);
						_CBMessages.fireSuccessMessage(_TEXT.APPS.SAVED);

						this.helpSetBackup(cmp, 'App was saved');

						if (callBack != null) callBack();
					} catch (e) {
						this.helpSetBackup(cmp, _TEXT.APPS.IS_NOT_SAVED + e.message);
						alert("Save App Callback ERROR:" + e);
					}
				} else {
					_RequestError(response, "c.saveAppTagsServer");
					_CBMessages.fireWarningMessage('Saving failed. Just System Admins can add Budget Application.');
					let errors = response.getError();
					this.helpSetBackup(cmp, _TEXT.APPS.IS_NOT_SAVED + ' ' + errors[0].message);
					_RequestError(response, _TEXT.APPS.IS_NOT_SAVED, cmp);
					_hideSpinner(cmp);
				}

			});

			let answer = _this.helpSaveTopDownSection(cmp);
			if (answer == null) return null;

			$A.enqueueAction(action);
		} catch (e) {
			alert('App Saving Error : ' + e);
		}
	},

	/**
	 * The method add L1, L2 ... into description of the identical lines before saving
	 * @param rows
	 */
	helpSetUniqueKeyBeforeSaving: function (rows) {
		try {
			if (rows.length === 0) return;
			let clones = [];
			let key;

			rows.forEach(function (row) {
				key = [row.account, row.dim6, row.dim7, row.dim8, row.dim9, row.dim10, row.description, row.title].join("");
				let rowsList = clones[key];
				if (rowsList === undefined) rowsList = [];
				rowsList.push(row);
				clones[key] = rowsList;
			});

			Object.values(clones).forEach(function (rowsList) {
				if (rowsList.length > 1) for (key = 0; key < rowsList.length; key++) rowsList[key].description = _isInvalid(rowsList[key].description) ? " L" + key : rowsList[key].description + " L" + key;
			});
		} catch (e) {
			alert("SetUniqueKeyBeforeSaving error" + e);
		}
	},

	helpConvertRowsToCBTags: function (cmp, rows, tagType) {
		const periodList = cmp.get("v.periods");
		let tags = [];

		rows.forEach(function (row) {
			//TODO Optimize one check for one row

			for (let i = 0; i < row.rowValues.length - 1; i++) {
				if (row.rowValues[i] === 0) continue;
				let tag = {
					cb4__Decimal1__c: row.rowValues[i],
					cb4__Decimal2__c: row.quantityValues[i],
					cb4__Decimal3__c: row.priceValues[i],
					cb4__Text1__c: tagType,
					cb4__Text2__c: !_isInvalid(row.lvl1Name) && (row.lvl1Name.toLowerCase() === 'expense'.toLowerCase() || row.lvl1Name.toLowerCase() === 'income') ? row.lvl1Name : row.ie.toLowerCase(),
					cb4__Text5__c: row.styleClass,
					cb4__Tag2__c: row.account,
					cb4__Tag3__c: periodList[i]
				};

				if (!_isInvalid(row.title)) tag.cb4__Text3__c = row.title.toString();
				if (tag.cb4__Text3__c == null || tag.cb4__Text3__c === '') tag.cb4__Text3__c = _TEXT.APPS.UNSPECIFIED_LINE_TITLE;
				if (!_isInvalid(row.description)) tag.cb4__Text4__c = row.description.toString();

				if (!_isInvalid(row.dim6)) tag.cb4__Tag6__c = row.dim6;
				if (!_isInvalid(row.dim7)) tag.cb4__Tag7__c = row.dim7;
				if (!_isInvalid(row.dim8)) tag.cb4__Tag8__c = row.dim8;
				if (!_isInvalid(row.dim9)) tag.cb4__Tag9__c = row.dim9;
				if (!_isInvalid(row.dim10)) tag.cb4__Tag10__c = row.dim10;

				if (!_isInvalid(row.productId)) tag.cb4__Product__c = row.productId;
				if (!_isInvalid(row.pricebookId)) tag.cb4__PriceBook__c = row.pricebookId;

				if (!_isInvalid(row.employeeId)) tag.cb4__Tag4__c = row.employeeId;
				if (!_isInvalid(row.rateId)) tag.cb4__Tag5__c = row.rateId;

				if (!_isInvalid(row.boolean1)) tag.cb4__Boolean1__c = row.boolean1;
				if (!_isInvalid(row.boolean2)) tag.cb4__Boolean2__c = row.boolean2;
				if (!_isInvalid(row.boolean3)) tag.cb4__Boolean3__c = row.boolean3;
				if (!_isInvalid(row.boolean4)) tag.cb4__Boolean4__c = row.boolean4;
				if (!_isInvalid(row.boolean5)) tag.cb4__Boolean5__c = row.boolean5;

				if (!_isInvalid(row.text6)) tag.cb4__Text6__c = row.text6;
				if (!_isInvalid(row.text7)) tag.cb4__Text7__c = row.text7;
				if (!_isInvalid(row.text8)) tag.cb4__Text8__c = row.text8;
				if (!_isInvalid(row.text9)) tag.cb4__Text9__c = row.text9;

				if (!_isInvalid(row.decimal6)) tag.cb4__Decimal6__c = row.decimal6;
				if (!_isInvalid(row.decimal7)) tag.cb4__Decimal7__c = row.decimal7;
				if (!_isInvalid(row.decimal8)) tag.cb4__Decimal8__c = row.decimal8;
				if (!_isInvalid(row.decimal9)) tag.cb4__Decimal9__c = row.decimal9;
				if (!_isInvalid(row.decimal10)) tag.cb4__Decimal10__c = row.decimal10;

				tags.push(tag);
			}

		});
		return tags;

	},

	helpSaveTopDownSection: function (cmp) {
		try {
			let expenseTopDownSubData = JSON.parse(JSON.stringify(cmp.get('v.expenseTopDownSubData')));
			let incomeTopDownSubData = JSON.parse(JSON.stringify(cmp.get('v.incomeTopDownSubData')));


			let emptyLineWarning = 'Lines containing only 0 cannot be saved';
			let emptyInputWarning = 'Each input must have a number';

			let needAskForEmptyInput;

			for (let i = expenseTopDownSubData.length; i--;) {
				let needAskForEmptyLine = true;
				for (let j = 0; expenseTopDownSubData[i].rowValues.length - 1 > j; j++) {
					if (_isInvalidNumber(expenseTopDownSubData[i].rowValues[j].v)) {
						needAskForEmptyInput = " expense " + expenseTopDownSubData[i].title + "(" + (j + 1) + ") " + "*" + expenseTopDownSubData[i].rowValues[j].v + "*";
						break;
					}
					if (parseFloat(expenseTopDownSubData[i].rowValues[j].v) !== 0) needAskForEmptyLine = false;
				}
				if (needAskForEmptyLine) {
					_CBMessages.fireWarningMessage(emptyLineWarning);
					_hideSpinner(cmp);
					return null;
				}
			}

			for (let i = incomeTopDownSubData.length; i--;) {
				let needAskForEmptyLine = true;
				for (let j = 0; incomeTopDownSubData[i].rowValues.length - 1 > j; j++) {
					if (_isInvalidNumber(incomeTopDownSubData[i].rowValues[j].v)) {
						needAskForEmptyInput = " expense " + incomeTopDownSubData[i].title + "(" + (j + 1) + ") " + "*" + incomeTopDownSubData[i].rowValues[j].v + "*";
						break;
					}
					if (parseFloat(incomeTopDownSubData[i].rowValues[j].v) !== 0) needAskForEmptyLine = false;
				}
				if (needAskForEmptyLine) {
					_CBMessages.fireWarningMessage(emptyLineWarning);
					_hideSpinner(cmp);
					return null;
				}
			}

			if (!_isInvalid(needAskForEmptyInput)) {
				_CBMessages.fireWarningMessage(emptyInputWarning);
				_cl("THE ISSUE IS IN THE INPUT FROM LINE: " + needAskForEmptyInput + " ", "orange");
				_hideSpinner(cmp);
				return null;
			}

			expenseTopDownSubData = this.objectsToArray(expenseTopDownSubData);
			incomeTopDownSubData = this.objectsToArray(incomeTopDownSubData);
			const topDownAmounts = expenseTopDownSubData.concat(incomeTopDownSubData);

			_CBRequest(cmp, "c.saveTopDownSubLinesServer", {"topDownAmounts": topDownAmounts}, null, null, null, null, null, null);
			return 'ok';
		} catch (e) {
			alert(e);
		}
	}
	,

	helpSaveChat: function (cmp, message) {
		let param = {"appId": cmp.get("v.app.Id"), "message": message};
		_CBRequest(cmp, "c.saveChatServer", param, null, null, null, null, false);
	}
	,

	helpCloneApp: function (cmp) {
		if (!confirm(_TEXT.APPS.CLONE_CONFIRM)) {
			return;
		}
		_showSpinner(cmp);

		setTimeout(function () {
			let app = cmp.get("v.app");
			app.cb4__Text3__c = app.cb4__Text3__c === undefined ? ' Cloned from "' + app.Name + '"' : app.cb4__Text3__c + ' Cloned from "' + app.Name + '"';
			app.Name = app.Name + ' Cloned';
			app.cb4__Text5__c = 'Cloned';
			app.cb4__Status__c = 'Open';
			app.Id = null;
			delete app.cb4__CBTSatellite__c;
			cmp.set("v.headerTitle", '');
			cmp.set("v.app", app);
			_CBMessages.fireWarningMessage(_TEXT.APPS.CLONE_COMPLETED);
			_hideSpinner(cmp);
		}, 10);

	}
	,

	helpDeleteApp: function (cmp) {
		if (!confirm(_TEXT.APPS.DELETE_CONFIRM)) {
			return;
		}
		_showSpinner(cmp);

		let _this = this;

		function callback() {
			_this.showTable(cmp);
			_this.helpGetAppList(cmp);
			_this.helpBackToMainTable(cmp);
		}

		let param = {"appId": cmp.get("v.app.Id")};
		_CBRequest(cmp, "c.deleteAppServer", param, null, callback, _TEXT.COMMON.DELETED, _TEXT.COMMON.DELETING_FAILED, false);
	}
	,

	/**
	 * The method adds a new line to the budget app
	 * @param cmp
	 * @param type income or expense section
	 */
	helpAddLine: function (cmp, type, row, isClone) {
		cmp.set("v.needSave", true);

		let splitRow = cmp.get("v.app.cb4__Decimal6__c");
		if (_isInvalid(splitRow)) splitRow = 0;
		const dis = 'disabled';

		type = type.toLowerCase();
		let accountSO = type === 'income' ? cmp.get('v.incomeAccountsSO') : cmp.get('v.expenseAccountsSO');
		let createNew = row !== undefined;
		let newLine = createNew ?  row : JSON.parse(JSON.stringify(cmp.get("v.totalData")[0])); // sample
		try {
			if(!createNew) {
				newLine.rowValues = newLine.rowValues.map(() => {
					return {"v": 0, "q": 0, "p": 0}
				});
				for (let i = 0; i < newLine.rowValues.length; i++) newLine.rowValues[i].t = i < splitRow ? dis : '';
				newLine.rowValues[0].rowTotal = 0; // line total
				newLine.rowValues[newLine.rowValues.length - 1].t = dis; // disable total column
				newLine.title = newLine.title != null && newLine.title.length > 0 ? accountSO[0].title : _TEXT.APPS.NEW_LINE_TITLE; // adding title like the first account
				newLine.account = _isInvalid(newLine.account) ? accountSO[0].value : newLine.account; // add account Id
				newLine.description = "";
				newLine.ie = type;
			}
			newLine.key = Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);// add unique index
			this.helpUpdateAppLineTitle(cmp, 'mass', newLine, isClone);
		} catch (e) {
			alert(e);
		}
		this.helpShowDetails(cmp, null, newLine);
	},

	/**
     {value:1.0, title:'Account'},
     {value:2.0, title:'Account:Description'},
     {value:3.0, title:'Account Code:Description'},
     {value:4.0, title:'Product:PriceBook'},
     {value:5.0, title:'Employee:Rate'},
     {value:6.0, title:'Dimension 1'},
     {value:7.0, title:'Dimension 2'},
     {value:8.0, title:'Dimension 3'},
     {value:9.0, title:'Dimension 4'},
     {value:10.0, title:'Dimension 5'},
     {value:11.0, title:'Dimension 1:Account'},
     {value:12.0, title:'Dimension 2:Account'},
     {value:13.0, title:'Dimension 3:Account'},
     {value:14.0, title:'Dimension 4:Account'},
     {value:15.0, title:'Dimension 5:Account'},
     {value:16.0, title:'Subtype:Account'},
     {value:17.0, title:'Account:Subtype'},
     {value:20.0, title:'Custom'},
	 *
	 * @param cmp
	 * @param trigger is the element that evoked this function. If (trigger === 'mass') title will be changed anyway
	 * @param row
	 */
	helpUpdateAppLineTitle: function (cmp, trigger, row, isClone) {
		console.group('DEBUG');
		try {
			let i, dimSO;
			if (row == null) row = cmp.get("v.row");
			const mt = trigger === 'mass'; // mass update
			const template = cmp.get("v.template");
			const titleRuleIdx = _isInvalid(template.cb4__Decimal6__c) ? 1.0 : template.cb4__Decimal6__c;
			const description = _isInvalid(row.description) ? '' : ':' + row.description;

			function getAccName() {
				let accountsSO = cmp.get("v.incomeAccountsSO");
				accountsSO = accountsSO.concat(cmp.get("v.expenseAccountsSO"));
				for (i = accountsSO.length; i--;) if (accountsSO[i].value === row.account) return accountsSO[i].title;
			}

			function getAccSubtypeName() {
				let accountSubtypeSO = cmp.get("v.accountToSubtypeSO");
				console.log('accountSubtypeSO', accountSubtypeSO);
				for (i = accountSubtypeSO.length; i--;) if (accountSubtypeSO[i].value === row.account) return accountSubtypeSO[i].title;
			}

			function getDimName(dimId, idx) {
				if (_isInvalid(dimId) || dimId === 'undefined') return "General";
				dimSO = cmp.get("v.d" + idx + "SO");
				for (i = dimSO.length; i--;) if (dimSO[i].value === row["dim" + idx]) return dimSO[i].title;
			}

			function getDimCodes(){
				let dimCode6 = getDimName(row.dim6, 6).split(':')[0];
				let dimCode7 = getDimName(row.dim7, 7).split(':')[0];
				let dimCode8 = getDimName(row.dim8, 8).split(':')[0];
				let dimCode9 = getDimName(row.dim9, 9).split(':')[0];
				let dimCode10 = getDimName(row.dim10, 10).split(':')[0];
				let result = (/^\d+$/.test(dimCode6)  ? dimCode6  : '') +
					(/^\d+$/.test(dimCode7)  ? ((dimCode6 !== '' && dimCode6 !== 'General') ? ('-' + dimCode7) : dimCode7)  : '') +
					(/^\d+$/.test(dimCode8)  ? (((dimCode6 !== '' && dimCode6 !== 'General') || (dimCode7 !== '' && dimCode7 !== 'General') ) ? ('-' + dimCode8) : dimCode8)  : '') +
					(/^\d+$/.test(dimCode9)  ? (((dimCode6 !== '' && dimCode6 !== 'General') || (dimCode7 !== '' && dimCode7 !== 'General') || (dimCode8 !== ''  && dimCode8 !== 'General') ) ? ('-' + dimCode9) : dimCode9)  : '') +
					(/^\d+$/.test(dimCode10) ? (((dimCode6 !== '' && dimCode6 !== 'General') || (dimCode7 !== '' && dimCode7 !== 'General') || (dimCode8 !== ''  && dimCode8 !== 'General') || (dimCode9 !== ''  && dimCode9 !== 'General')) ? ('-' + dimCode10) : dimCode10) : '') ;
				return result === '' ? '' : ('(' + result + ')');
			}

			function getAccNameWithoutCode(){
				let accName = getAccName();
				accName = accName !== undefined ? accName.split(':') : ['','The selected Account is not in the Budget Template.'];
				return accName.length > 1 ? accName[1] : accName[0];
			}

			console.log('row', JSON.parse(JSON.stringify(row)));
			console.log('titleRuleIdx', titleRuleIdx);
			console.log('getAccName()', getAccName());
			console.log('getAccSubtypeName()', getAccSubtypeName());
			switch (titleRuleIdx) {
				case 1.0:
					if (mt || trigger === 'account') row.title = getAccName();
					break;
				case 2.0:
					if (mt || trigger === 'account' || trigger === 'description') row.title = getAccName() + description;
					break;
				case 3.0:
					if (mt || trigger === 'account' || trigger === 'description') row.title = getAccName().split(':')[0] + description;
					break;
				/*case 4.0:
                     row.title = getAccName().split(':')[0] + description;
                     break;*/
				case 5.0:
					if (mt || trigger === 'account' || trigger === 'empRate') {
						let employeeSO = cmp.get("v.employeeSO");
						for (let i = employeeSO.length; i--;) {
							if (employeeSO[i].value === row.employeeId) {
								if (row.title.includes(_TEXT.APPS.TITLE_SEPARATOR)) row.title = row.title.split(_TEXT.APPS.TITLE_SEPARATOR)[0];
								row.title = row.title + _TEXT.APPS.TITLE_SEPARATOR + " " + employeeSO[i].title;
							}
						}
					}
					break;
				case 6.0:
					if (mt || trigger === 'dimension6') row.title = getDimName(row.dim6, 6);
					break;
				case 7.0:
					if (mt || trigger === 'dimension7') row.title = getDimName(row.dim7, 7);
					break;
				case 8.0:
					if (mt || trigger === 'dimension8') row.title = getDimName(row.dim8, 8);
					break;
				case 9.0:
					if (mt || trigger === 'dimension9') row.title = getDimName(row.dim9, 9);
					break;
				case 10.0:
					if (mt || trigger === 'dimension10') row.title = getDimName(row.dim10, 10);
					break;
				case 11.0:
					if (mt || trigger === 'account' || trigger === 'dimension6') row.title = getDimName(row.dim6, 6) + ":" + getAccName();
					break;
				case 12.0:
					if (mt || trigger === 'account' || trigger === 'dimension7') row.title = getDimName(row.dim7, 7) + ":" + getAccName();
					break;
				case 13.0:
					if (mt || trigger === 'account' || trigger === 'dimension8') row.title = getDimName(row.dim8, 8) + ":" + getAccName();
					break;
				case 14.0:
					if (mt || trigger === 'account' || trigger === 'dimension9') row.title = getDimName(row.dim9, 9) + ":" + getAccName();
					break;
				case 15.0:
					if (mt || trigger === 'account' || trigger === 'dimension10') row.title = getDimName(row.dim10, 10) + ":" + getAccName();
					break;
				case 16.0:
					if (mt || trigger === 'account') row.title = getAccSubtypeName() + "     " + getAccName();
					break;
				case 17.0:
					if (mt || trigger === 'account') row.title = getAccName() + "     " + getAccSubtypeName();
					break;
				case 18.0:
					if (mt || trigger === 'account'|| trigger === 'dimension6'|| trigger === 'dimension7'|| trigger === 'dimension8'|| trigger === 'dimension9'|| trigger === 'dimension10') row.title = getAccNameWithoutCode() + " " + getDimCodes();
					break;
				case 19.0:
					if (mt || trigger === 'account'|| trigger === 'dimension6'|| trigger === 'dimension7'|| trigger === 'dimension8'|| trigger === 'dimension9'|| trigger === 'dimension10' || trigger === 'description'){
						row.title = getAccNameWithoutCode() + " " + getDimCodes()
					}
					break;
				case 20.0:
					if (_isInvalid(row.title)) row.title = _TEXT.APPS.UNSPECIFIED_LINE_TITLE;
					break;
				default:
					alert("Specify Title Rule in the App Template")
			}

			if (_isInvalid(row.title) || row.title.length < 2) row.title = _TEXT.APPS.UNSPECIFIED_LINE_TITLE;
			if(isClone) row.title += ' [Cloned]';
			cmp.set("v.row", row);
			return row;
		} catch (e) {
			console.log('error', e);
			alert('Update App Line Title ERROR:' + e);
		}
		console.groupEnd();
	},

	helpApplyTitleRule: function (cmp) {

		//if (!confirm('Are you sure you want to adjust all the titles using the template rule?')) return null;
		_showSpinner(cmp);
		let _this = this;
		window.setTimeout(
			$A.getCallback(function () {

				try {

					let incomeRows = cmp.get("v.incomeData");
					let grantIncome = cmp.get('v.grantIncomeData');
					let expenseRows = cmp.get("v.expenseData");
					let grantExpense = cmp.get('v.grantExpenseData');


					function applyTitle(row) {
						return _this.helpUpdateAppLineTitle(cmp, 'mass', row, false);
					}

					incomeRows = incomeRows.map(applyTitle);
					expenseRows = expenseRows.map(applyTitle);
					for(let i = 0; i < grantIncome.length; i++){
						let total = grantIncome[i][1].shift();
						grantIncome[i][1] = grantIncome[i][1].map(applyTitle);
						grantIncome[i][1].unshift(total);
					}
					for(let i = 0; i < grantExpense.length; i++){
						let total = grantExpense[i][1].shift();
						grantExpense[i][1] = grantExpense[i][1].map(applyTitle);
						grantExpense[i][1].unshift(total);
					}

					cmp.set("v.incomeData", incomeRows);
					cmp.set('v.grantIncomeData', grantIncome);
					cmp.set("v.expenseData", expenseRows);
					cmp.set('v.grantExpenseData', grantExpense);

					_CBMessages.fireSuccessMessage('Ok');
					_hideSpinner(cmp);

					_this.helpSetBackup(cmp, 'Title rule was applied');
				} catch (e) {
					alert("Apply Title Rule ERROR " + e);
				}

			}, 10));
	},

	helpGetMainAppSO: function (cmp) {
		let action = cmp.get("c.getInitialSOServer");
		action.setCallback(this, function (response) {
			let state = response.getState();
			let options;
			if (state === "SUCCESS") {
				options = response.getReturnValue();
				if (options['template'] != null) cmp.set("v.templateSO", options['template']);
				if (options['period'] != null) cmp.set("v.periodSO", options['period']);
				if (options['department'] != null) cmp.set("v.departmentSO", options['department']);
				if (options['app'] != null) cmp.set("v.appSO", options['app']);
				if (options['user'] != null) cmp.set("v.userSO", options['user']);
				if (options['userWithPermSet'] != null) cmp.set("v.userWithPermSetSO", options['userWithPermSet']);
				if (options['userAll'] != null) cmp.set("v.userAllSO", options['userAll']);
				if (options['queue'] != null) cmp.set("v.queueSO", options['queue']);
			} else {
				_cl('Server Error', 'red');
				_RequestError(response, _TEXT.APPS.FAILED_INITIAL);
			}
		});
		$A.enqueueAction(action);
	}
	,

	helpHandleTableButtons: function (cmp, event) {
		const action = event.getParam('action');
		const row = event.getParam('row');
		switch (action.name) {
			case 'redirectToSheet':
				_showSpinner(cmp);
				_CBRedirect.toComponent('c:CBBudgetApplicationSheet', {'recordId': row.Id});
				break;
			case 'editApp': // Edit button is pressed
				try {
					_showSpinner(cmp);
					cmp.set("v.app.Id", row.Id);
					cmp.set("v.mode", 'single');
					this.helpRefreshSingleApp(cmp);
					this.showSingle(cmp);
				} catch (e) {
					_CBMessages.fireErrorMessage(e);
				}
				break;
			case 'deleteApp': // Delete button is pressed
				try {
					cmp.set("v.app.Id", row.Id);
					this.helpDeleteApp(cmp);
				} catch (e) {
					_CBMessages.fireErrorMessage(e);
				}
				break;
		}
	},

/////// CALCULATION RULES ///////
	runCalculationRuleFlow: function (cmp) {
		this.helpConvertToSimpleRow(cmp); // all calculation rule rows
	},


	helpApplyCalcRules: function (cmp, step, callback) {

		_showSpinner(cmp);
		try {
			let income = JSON.parse(JSON.stringify(cmp.get("v.incomeData")));
			let grantIncome = JSON.parse(JSON.stringify(cmp.get('v.grantIncomeData')));
			for(let i = 0; i < grantIncome.length; i++){
				grantIncome[i][1].shift();
				income = income.concat(grantIncome[i][1]);
			}
			this.objectsToArray(income);
			let expenses = JSON.parse(JSON.stringify(cmp.get("v.expenseData"))); // clone expenses
			let grantExpense = JSON.parse(JSON.stringify(cmp.get('v.grantExpenseData')));
			for(let i = 0; i < grantExpense.length; i++){
				grantExpense[i][1].shift();
				expenses = expenses.concat(grantExpense[i][1]);
			}
			this.objectsToArray(expenses);
			let totals = JSON.parse(JSON.stringify(cmp.get("v.totalData"))); // clone totals
			this.objectsToArray(totals);

			let action = cmp.get("c.getCalcRulesSyntheticLines");
			action.setParams({
				"appId": cmp.get("v.app.Id"),
				"income": income,
				"expense": expenses,
				"totals": totals,
				"step": step
			});
			action.setCallback(this, function (response) {
				let state = response.getState();
				if (state === "SUCCESS") {
					try {
						let tagMap = response.getReturnValue();
						if (_isInvalid(tagMap)) { // if step omitted, there is not needed to run the next step
							_CBMessages.fireOtherMessage("Step " + step + ": " + _TEXT.APPS.NOTHING_CALCULATED);
							_hideSpinner(cmp);
							return;
						}

						let incomeSynth = this.validateSynth(tagMap.income, cmp);
						let expenseSynth = this.validateSynth(tagMap.expense, cmp);

						incomeSynth = this.arrayToObjects(incomeSynth, cmp);
						expenseSynth = this.arrayToObjects(expenseSynth, cmp);
						let income = cmp.get("v.incomeData");
						let expense = cmp.get("v.expenseData");

						// delete old calculated rows
						if (step < 2) {
							income = this.helpDeleteOldCalcRuleLines(income);
							expense = this.helpDeleteOldCalcRuleLines(expense);
						}

						if (incomeSynth.length > 0) {
							incomeSynth = this.helpSetDisableInputs(incomeSynth);
							income = income.concat(incomeSynth);
							cmp.set("v.incomeData", income);
						}

						if (expenseSynth.length > 0) {
							expenseSynth = this.helpSetDisableInputs(expenseSynth);
							expense = expense.concat(expenseSynth);
							cmp.set("v.expenseData", expense);
						}

						this.helpCalculateTotalRows(cmp, 'income');
						this.helpCalculateTotalRows(cmp, 'expense');
						this.helpCalculateMarginRow(cmp); // calculate margin / difference
						this.helpTitleRows(cmp);
						this.helpApplyTitleRule(cmp);

						this.helpSetBackup(cmp, 'Calculation rules were applied');

						_CBMessages.fireSuccessMessage("Step " + step + ": " + _TEXT.APPS.CALCULATED);

						if (!_isInvalid(callback)) callback();
					} catch (e) {
						alert('CALCULATION RULES RESPONSE ERROR:' + e);
					}

				} else {
					_RequestError(response, _TEXT.APPS.CALCULATION_ERROR, cmp);
				}
				_hideSpinner(cmp);
			});
			$A.enqueueAction(action);
		} catch (e) {
			alert('CALCULATION RULES ERROR:' + e);
			_hideSpinner(cmp);
		}
	},

	validateSynth: function (synthAmounts, cmp){
		let accSO = cmp.get('v.incomeAccountsSO').concat(cmp.get('v.expenseAccountsSO'));
		let accIdsSet = new Set(), missedAccounts = false, newSynthAmounts = [];
		for(let i = 0; i < accSO.length; i++){
			accIdsSet.add(accSO[i].value);
		}
		for(let i = 0; i < synthAmounts.length; i++){
			if(!accIdsSet.has(synthAmounts[i].account)) missedAccounts = true;
			else newSynthAmounts.push(synthAmounts[i]);
		}
		if(missedAccounts) _CBMessages.fireWarningMessage('There are missing Accounts from the Budget Template. Add needed Accounts to the Budget Template or select another Result Account in the Calculation Rules.', null);
		return newSynthAmounts;
	},

	helpRefreshCalcRules: function (cmp) {

		let expense = cmp.get("v.expenseData");
		let income = cmp.get("v.incomeData");
		expense = expense.filter((item) => item.styleClass !== 'calcRule');
        income = income.filter((item) => item.styleClass !== 'calcRule');
        cmp.set("v.expenseData", expense);
        cmp.set("v.incomeData", income);
        let grantExpenses = cmp.get('v.grantExpenseData');
        let grantIncome = cmp.get('v.grantIncomeData');
		for(let i = 0; i < grantExpenses.length; i++){
			for(let j = 0; j < grantExpenses[i][1].length; j++){
				if(grantExpenses[i][1][j].styleClass === "calcRule"){
					let crLine = grantExpenses[i][1].splice(j,1);
					for(let k = 0; k < grantExpenses[i][1][0].rowValues.length; k++){
						grantExpenses[i][1][0].rowValues[k].v -= parseFloat(crLine.rowValues[k].v);
					}
				}
			}
		}
		for(let i = 0; i < grantIncome.length; i++){
            for(let j = 0; j < grantIncome[i][1].length; j++) {
                if (grantIncome[i][1][j].styleClass === "calcRule") {
                    let crLine = grantIncome[i][1].splice(j, 1);
                    for (let k = 0; k < grantIncome[i][1][0].rowValues.length; k++) {
                        grantIncome[i][1][0].rowValues[k].v -= parseFloat(crLine.rowValues[k].v);
                    }
                }
            }
		}
		cmp.set('v.grantExpenseData', grantExpenses);
		cmp.set('v.grantIncomeData', grantIncome);

		let _this = this;
		let step3 = function () {
			_this.helpApplyCalcRules(cmp, 3);
		};
		let step2 = function () {
			_this.helpApplyCalcRules(cmp, 2, step3);
		};
		this.helpApplyCalcRules(cmp, 1, step2);
	},
	/////// CALCULATION RULES ///////


	/////// BACKUP ///////
	helpSetBackup: function (cmp, title) {
		const app = cmp.get('v.app');
		let expense = cmp.get("v.expenseData");
		let grantExpense = JSON.parse(JSON.stringify(cmp.get('v.grantExpenseData')));
		for(let i = 0; i < grantExpense.length; i++){
			grantExpense[i][1].shift();
			expense = expense.concat(grantExpense[i][1]);
		}
		let income = cmp.get("v.incomeData");
		let grantIncome = JSON.parse(JSON.stringify(cmp.get('v.grantIncomeData')));
		for(let i = 0; i < grantIncome.length; i++){
			grantIncome[i][1].shift();
			income = income.concat(grantIncome[i][1]);
		}
		let backup = {};
		backup.app = app;
		backup.expense = expense;
		backup.income = income;

		let params = {};
		params.recordId = app.Id;
		params.title = _isInvalid(title) ? 'General' : title;
		params.backup = JSON.stringify(backup);

		_CBRequest(cmp, "c.insertBackupLog", params, null, null, null, 'Failed to set backup', false);
	},

	helpGetBackupList: function (cmp) {
		_CBRequest(cmp, "c.getBackupLogList", {recordId: cmp.get("v.app.Id")}, "v.backupList", null, null, 'Failed to get backup list', false);
	},

	helpApplyBackup: function (cmp, backupId) {
		_showSpinner(cmp);
		this.helpSetBackup(cmp, 'Backup was restored');

		let _this = this;

		let applyBackup = function () {
			try {
				const backupJSON = JSON.parse(cmp.get("v.backupJSON"));
				cmp.set('v.app', backupJSON.app);
				cmp.set('v.expenseData', backupJSON.expense);
				cmp.set('v.grantExpenseData', []);
				cmp.set('v.incomeData', backupJSON.income);
				cmp.set('v.grantIncomeData', []);
				_CBMessages.fireSuccessMessage("Restored");

				_this.helpCalculateTotalRows(cmp, 'income');
				_this.helpCalculateTotalRows(cmp, 'expense');
				_this.helpCalculateMarginRow(cmp); // calculate margin / difference

			} catch (e) {
				alert(" Apply Backup ERROR " + e);
			}
		};

		_CBRequest(cmp, "c.getBackupLog", {backupId: backupId}, "v.backupJSON", applyBackup, null, 'Failed to apply backup. Please do not save the app', true);
	},
	/////// BACKUP ///////

	/////// AUTOFILL LINES ///////
	helpGetGenerateLinesByTypeSO: function (cmp) {
		let r = [];
		let arr, i;
		r.push('Account');
		r.push('Employee');
		r.push('Product');

		function addDimName(idx) {
			arr = cmp.get("v.d" + idx + "SO");
			if (arr !== null && arr !== undefined && arr.length) r.push(cmp.get("v.d" + idx + "name"));
		}

		for (i = 6; i <= 10; i++) addDimName(i);
		cmp.set("v.generateLinesByTypeSO", r);

	},
	helpGenerateListOfEmptyLines: function (cmp) {
		try {
			const selectedType = cmp.get("v.generateLinesByType");
			let listOfSplitIncome = [];
			let listOfSplitExpense = [];
			let template = cmp.get("v.template");

			let newLine = JSON.parse(JSON.stringify(cmp.get("v.totalData")[0])); // sample

			for (let i = newLine.rowValues.length; i--;) newLine.rowValues[i] = {"v": 1, "q": 0, "p": 0}; // zeroing column values
			newLine.rowValues[0].rowTotal = 0; // line total
			newLine.rowValues[newLine.rowValues.length - 1].t = 'disabled'; // disable total column
			newLine.description = "";

			let newIncomeLines = [];
			let newExpenseLines = [];

			if (selectedType === 'Account') {
				listOfSplitIncome = cmp.get("v.incomeAccountsSO");
				listOfSplitExpense = cmp.get("v.expenseAccountsSO");

				for (let i = 0; i < listOfSplitIncome.length; i++) {
					let newIncomeLine = JSON.parse(JSON.stringify(newLine));
					newIncomeLine.key = Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);// add unique index
					newIncomeLine.title = listOfSplitIncome[i].title; // adding title like the first account
					newIncomeLine.account = listOfSplitIncome[i].value; // add account Id
					newIncomeLine.ie = 'income';
					newIncomeLines.push(newIncomeLine);
				}

				for (let i = 0; i < listOfSplitExpense.length; i++) {
					let newExpenseLine = JSON.parse(JSON.stringify(newLine));
					newExpenseLine.key = Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);// add unique index
					newExpenseLine.title = listOfSplitExpense[i].title; // adding title like the first account
					newExpenseLine.account = listOfSplitExpense[i].value; // add account Id
					newExpenseLine.ie = 'expense';
					newExpenseLines.push(newExpenseLine);
				}
			}

			cmp.set("v.incomeData", newIncomeLines);
			cmp.set("v.expenseData", newExpenseLines);

			$A.util.addClass(cmp.find("generatorModal"), "slds-hide");
			$A.util.addClass(cmp.find("generatorBackGround"), "slds-hide");
			_hideSpinner(cmp);

		} catch (e) {
			alert(e);
		}
	},
/////// AUTOFILL LINES ///////

/////// VALIDATION ///////
	helpValidateInitialSaving: function (cmp) {
		let app = cmp.get("v.app");
		if (_isInvalid(app.Name) || app.Name === 'New App') {
			$(".initTitle").effect("shake", "slow");
			return _TEXT.APPS.VALIDATE_INIT_TITLE;
		}
		if (_isInvalid(app.cb4__Tag2__c)) {
			$(".initTemplate").effect("shake", "slow");
			return _TEXT.APPS.VALIDATE_INIT_TEMPLATE;
		}
		if (_isInvalid(app.cb4__Tag3__c)) {
			$(".initPeriod").effect("shake", "slow");
			return _TEXT.APPS.VALIDATE_INIT_PERIOD;
		}
		return null;
	}
	,

/////// VALIDATION ///////

	/**
	 * MAIN TABLE
	 * @param cmp
	 */
	helpGenerateMainStructure: function (cmp) {
		try {
			let apps = cmp.get("v.apps");
			const appDimension = cmp.get("v.appDimension");
			let expandedRows = [];
			let items = [];
			let data = {};
			let i;

			//_cl('DIM:' + JSON.stringify(appDimension), 'lightgreen');
			_cl('DIM:' + JSON.stringify(appDimension.cb4__Dimension4__c), 'lightgreen');
			let dim6 = appDimension.cb4__Dimension4__c;
			_cl('DIM:' + JSON.stringify(dim6), 'lightgreen');

			let queue = cmp.get("v.queueSO");
			let users = cmp.get("v.userSO");
			let userWithPermSet = cmp.get("v.userWithPermSetSO");
			let userQueueMap = {};
			if (queue !== null && queue !== undefined) for (i = queue.length; i--;) userQueueMap[queue[i].value] = queue[i].title;
			if (users !== null && users !== undefined) for (i = users.length; i--;) userQueueMap[users[i].value] = users[i].title;
			if (userWithPermSet !== null && userWithPermSet !== undefined) for (i = userWithPermSet.length; i--;) userQueueMap[userWithPermSet[i].value] = userWithPermSet[i].title;

			const actions = [
				{label: 'Edit', name: 'editApp'},
				{label: 'Delete', name: 'deleteApp'}
			];

			for (i = 0; i < apps.length; i++) {
				expandedRows.push(apps[i].Id);
				let item = {};
				item.appId = apps[i].Id;
				item.parent = apps[i].cb4__Tag1__c == null ? '#' : apps[i].cb4__Tag1__c;
				item.appName = apps[i].Name;
				item.BA = apps[i].cb4__TagLabel__c;
				item.template = _isInvalid(apps[i].cb4__Tag2Name__c) ? "⛔ Not specified" : apps[i].cb4__Tag2Name__c;
				item.period = _isInvalid(apps[i].cb4__Tag3Name__c) ? "⛔ Not specified" : apps[i].cb4__Tag3Name__c;
				item.department = _isInvalid(apps[i].cb4__Tag4Name__c) ? "⛔ Not specified" : apps[i].cb4__Tag4Name__c;
				item._children = [];
				item.Id = apps[i].Id;
				item.totalIncome = _isInvalid(apps[i].cb4__Decimal1__c) ? 0 : parseFloat(apps[i].cb4__Decimal1__c).toFixed(0);
				item.totalExpense = _isInvalid(apps[i].cb4__Decimal2__c) ? 0 : parseFloat(apps[i].cb4__Decimal2__c).toFixed(0);
				item.totalDiff = item.totalIncome - item.totalExpense;
				item.status = apps[i].cb4__Status__c;
				item.owner = userQueueMap[apps[i].OwnerId];
				item.lmdate = $A.localizationService.formatDate(apps[i].LastModifiedDate, "MMM dd, yyyy, hh:mm:ss a");
				item.lmby = userQueueMap[apps[i].LastModifiedById];
				item.description = ((!_isInvalid(apps[i].cb4__Tag2Name__c)) && apps[i].cb4__Tag2__r.cb4__Text2__c === "Totals" ? "" : "🛒 ") + (_isInvalid(apps[i].cb4__Text3__c) ? "" : apps[i].cb4__Text3__c);
				item.d6 = apps[i].cb4__Tag6Name__c;
				item.d7 = apps[i].cb4__Tag7Name__c;
				item.d8 = apps[i].cb4__Tag8Name__c;
				item.d9 = apps[i].cb4__Tag9Name__c;
				item.d10 = apps[i].cb4__Tag10Name__c;
				data[item.appId] = item;
			}

			for (let key in data) {
				let item = data[key];
				item.appId = '/' + item.appId;
				let parent = data[item.parent];
				delete item.parent;
				delete item.parent;
				if (parent == null) {
					items.push(item);
					continue;
				}
				parent._children.push(item);
			}
			let d4Name = cmp.get("v.appDim4name");
			let d5Name = cmp.get("v.appDim5name");
			let d6Name = cmp.get("v.appDim6name");
			let d7Name = cmp.get("v.appDim7name");
			let d8Name = cmp.get("v.appDim8name");
			let d9Name = cmp.get("v.appDim9name");
			let d10Name = cmp.get("v.appDim10name");

			let gridColumns = [
				{
					type: 'url',
					fieldName: 'appId', // url
					label: 'App', // header
					initialWidth: 350,
					typeAttributes: {
						label: {fieldName: 'BA'/*, title: 'redirect'*/} , // link name
						tooltip: ''
					}
				},
				{
					type: "button",
					label: 'View',
					initialWidth: 85,
					typeAttributes: {
						fieldName: 'appId',
						label: 'summary',
						class: 'sheetButton',
						variant: 'base',
						name: 'redirectToSheet',
						value: 'test',
						title: 'Click on this for complete view of all GL Accounts at consolidated level'
					}
				}
			];

			let displaySet = {};
			displaySet.income = appDimension.cb4__Decimal1__c.vi === 't';
			displaySet.expense = appDimension.cb4__Decimal2__c.vi === 't';
			displaySet.difference = appDimension.cb4__Decimal3__c.vi === 't';
			displaySet.description = appDimension.cb4__Text1__c.vi === 't';
			displaySet.template = appDimension.cb4__Dimension2__c.vi === 't';
			displaySet.period = appDimension.cb4__Dimension3__c.vi === 't';
			displaySet.owner = appDimension.cb4__Owner__c.vi === 't';
			displaySet.lmdate = appDimension.cb4__LastModifiedDate__c.vi === 't';
			displaySet.lmby = appDimension.cb4__LastModifiedBy__c.vi === 't';
			displaySet.status = appDimension.cb4__Status__c.vi === 't';
			displaySet.department = appDimension.cb4__Dimension4__c.vi === 't';
			displaySet.dim6 = appDimension.cb4__Dimension6__c.vi === 't';
			displaySet.dim7 = appDimension.cb4__Dimension7__c.vi === 't';
			displaySet.dim8 = appDimension.cb4__Dimension8__c.vi === 't';
			displaySet.dim9 = appDimension.cb4__Dimension9__c.vi === 't';
			displaySet.dim10 = appDimension.cb4__Dimension10__c.vi === 't';

			if (displaySet.income) gridColumns.push({
				type: 'number',
				fieldName: 'totalIncome',
				label: 'Income',
				maximumFractionDigits: 0,
				typeAttributes: {maximumFractionDigits: 0, minimumFractionDigits: 0},
				initialWidth: 105,
			});

			if (displaySet.expense) gridColumns.push({
				type: 'number',
				fieldName: 'totalExpense',
				label: 'Expense',
				typeAttributes: {maximumFractionDigits: 0, minimumFractionDigits: 0},
				initialWidth: 105,
			});

			if (displaySet.difference) gridColumns.push({
				type: 'number',
				fieldName: 'totalDiff',
				label: 'Total',
				typeAttributes: {maximumFractionDigits: 0, minimumFractionDigits: 0},
				initialWidth: 105,
			});


			if (displaySet.period) gridColumns.push({
				type: 'text',
				fieldName: 'period',
				label: 'Period',
				initialWidth: 84,
			});

			if (displaySet.owner) gridColumns.push({
				type: 'text',
				fieldName: 'owner',
				label: 'Owner',
				initialWidth: 120,
			});

			if (displaySet.status) gridColumns.push({
				type: 'text',
				fieldName: 'status',
				label: 'Status',
				initialWidth: 75,
			});

			if (displaySet.department) gridColumns.push({
				type: 'text',
				fieldName: 'department',
				label: d4Name,
				initialWidth: 100,
			});

			if (displaySet.template) gridColumns.push({
				type: 'text',
				fieldName: 'template',
				label: 'Template',
				initialWidth: 100,
			});

			if (d6Name != null && displaySet.dim6) gridColumns.push({
				type: 'text',
				fieldName: 'd6',
				label: d6Name,
				initialWidth: 150,
			});
			if (d7Name != null && displaySet.dim7) gridColumns.push({
				type: 'text',
				fieldName: 'd7',
				label: d7Name,
				initialWidth: 150,
			});
			if (d8Name != null && displaySet.dim8) gridColumns.push({
				type: 'text',
				fieldName: 'd8',
				label: d8Name,
				initialWidth: 150,
			});
			if (d9Name != null && displaySet.dim9) gridColumns.push({
				type: 'text',
				fieldName: 'd9',
				label: d9Name,
				initialWidth: 150,
			});
			if (d10Name != null && displaySet.dim10) gridColumns.push({
				type: 'text',
				fieldName: 'd10',
				label: d10Name,
				initialWidth: 150,
			});
			if (displaySet.lmby) gridColumns.push({
				type: 'text',
				fieldName: 'lmby',
				label: 'Last Modified By',
				initialWidth: 120,
			});
			if (displaySet.lmdate) gridColumns.push({
				type: 'text',
				fieldName: 'lmdate',
				label: 'Last Modified Date',
				initialWidth: 188,
			});
			if (displaySet.description) gridColumns.push({
				type: 'text',
				fieldName: 'description',
				label: 'Description',
			});


			gridColumns.push({
				type: 'action',
				typeAttributes: {rowActions: actions}
			});

			function deleteEmptyChild(items) {
				items.forEach(function (item) {
					item._children.length === 0 ? delete item._children : deleteEmptyChild(item._children);
				});
			}

			deleteEmptyChild(items);

			function getDepth(item, depthValue){
				if(item._children !== undefined){
					let childDepths = [];
					item._children.forEach(child => childDepths.push(getDepth(child, depthValue + 1)));
					depthValue = Math.max(...childDepths);
				}
				return depthValue;
			}
			let maxDepth = 0;
			for(let i = 0; i < items.length; i++) {
				maxDepth = Math.max(getDepth(items[i], 0), maxDepth);
			}
			let hlevels = [];
			for(let depth = 1; depth <= maxDepth; depth++) {
				hlevels.push({value: depth, title: depth === 1 ? 'None' : depth});
			}

			if(maxDepth !== 0) cmp.set('v.hideLevels', hlevels);

			cmp.set('v.gridColumns', gridColumns);
			cmp.set('v.gridData', items);
			cmp.set('v.gridExpandedRows', expandedRows);
			cmp.set('v.showStructure', true);
		} catch (e) {
			alert(e);
		}
	},

	helpUpdateApps: function (cmp) {
		_CBRequest(cmp, "c.updateApps", null, null, null, 'Updated', 'Error while updating', true);
	},

	helpRecalculateTotals: function (cmp) {
		let _this = this;
		try {
			_showSpinner(cmp);
			let params = null;
			let lvl = 1;
			let BAMap = {};
			const channel = '/event/cb4__CB_Custom_Event__e';
			const replayId = -1;
			const empApi = cmp.find("empApi");

			function callbackGetBaList(cmp, response) {
				_cl('lvl: ' + lvl);
				let resp = response.getReturnValue();
				//_cl('resp: ' + JSON.stringify(resp), 'green');
				if (!_isInvalid(resp) && resp.length > 0 && lvl < 20) {
					//BAMap[lvl] = resp;
					params = [];
					resp.forEach(function (ba) {
						_cl(JSON.stringify(ba['Id']));
						params.push(ba['Id']);
					});
					BAMap[lvl] = params;
					lvl++;
					_CBRequest(cmp, 'c.getBAListServer', {"parentIdList": params}, null, callbackGetBaList, null, 'Error!', false);
				} else {
					_cl(JSON.stringify(BAMap), 'purple');
					_CBRequest(cmp, 'c.recalculateTotalsWithBatchServer', {"baMap":BAMap, "lvl":(lvl - 1)}, null, callbackRecalcJob, null, 'Error!', false);

					/* for (let i = lvl; --i; i === 0) {
                        //_cl('i: ' + i + ', list: ' + BAMap[i].length);
                        _CBRequest(cmp, 'c.runRefreshAppsServer', {
                            "lvl": i,
                            "listOfAppIds": BAMap[i]
                        }, null, callbackRecalc, null, 'Error!', false);
                    } */
				}
			}

			/* function callbackRecalc(cmp, response) {
                let resp = response.getReturnValue();
                _cl('recalculated lvl: ' + JSON.stringify(resp), 'blue');
                if (resp === 1) {
                    _this.helpGetAppList(cmp);
                    //_hideSpinner(cmp);
                }
            } */

			function callbackRecalcJob(cmp, response) {
				let jobId = response.getReturnValue();
				_cl('recalculated jobId: ' + JSON.stringify(jobId), 'blue');
				empApi.subscribe(channel, replayId, (message)=>{
					console.log('message: ' + JSON.stringify(message));
					const obj = message.data.payload;
					console.log('obj: ' + JSON.stringify(obj));
					const eventName = obj.cb4__Event_Name__c;
					const eventStatus = obj.cb4__Status__c;
					const eventJobId = obj.cb4__Text1__c;
					if (eventName == 'BATotals' && jobId == eventJobId) {
						_CBMessages.fireSuccessMessage('Totals recalculation: ' + eventStatus);
						empApi.unsubscribe(cmp.get('v.subscription'));
						_this.helpGetAppList(cmp);
					}
				}).then(function(newSubscription) {
					console.log("newSubscription: " + JSON.stringify(newSubscription));
					cmp.set("v.subscription", newSubscription);
				});
			}

			_CBRequest(cmp, 'c.getBAListServer', {"parentIdList": params}, null, callbackGetBaList, null, 'Error!', false);
		} catch(e) {
			alert(e);
		}
	},

	helpApplyPageFilters: function (cmp) {
		try {
			_showSpinner(cmp);
			let appAccFilter = cmp.get('v.appAccFilter');
			let d6Filter = cmp.get("v.d6filter");
			let d7Filter = cmp.get("v.d7filter");
			let d8Filter = cmp.get("v.d8filter");
			let d9Filter = cmp.get("v.d9filter");
			let d10Filter = cmp.get("v.d10filter");

			let pageFilter = {};
			if (!_isInvalid(appAccFilter)) pageFilter.cb4__Tag2__c = appAccFilter;
			if (!_isInvalid(d6Filter)) pageFilter.cb4__Tag6__c = d6Filter;
			if (!_isInvalid(d7Filter)) pageFilter.cb4__Tag7__c = d7Filter;
			if (!_isInvalid(d8Filter)) pageFilter.cb4__Tag8__c = d8Filter;
			if (!_isInvalid(d9Filter)) pageFilter.cb4__Tag9__c = d9Filter;
			if (!_isInvalid(d10Filter)) pageFilter.cb4__Tag10__c = d10Filter;

			if(appAccFilter !== '' || d8Filter !== ''){
				cmp.set('v.blockAddBtns', true);
			}else{
				cmp.set('v.blockAddBtns', false);
			}

			cmp.set("v.pageFilter", pageFilter);
			this.disableButtonSave(cmp);

			this.helpRefreshSingleApp(cmp);
		} catch (e) {
			alert(e);
		}

	}
	,

	helpFindNeededRow: function (cmp, key) {
		const income = cmp.get("v.incomeData");
		for (let i = 0; i < income.length; i++) if (income[i].key === key) return income[i];

		const expense = cmp.get("v.expenseData");
		for (let i = 0; i < expense.length; i++) if (expense[i].key === key) return expense[i]
	},

	helpGetRowInfo: function (cmp, key) {
		try {
			const row = this.helpFindNeededRow(cmp, key);
			let r = [];

			let acc = {key: 'Account'};
			const accId = row.account;
			let incomeAccounts = cmp.get("v.incomeAccountsSO");
			let expenseAccounts = cmp.get("v.expenseAccountsSO");
			for (let i = 0; i < incomeAccounts.length; i++) {
				if (incomeAccounts[i].value === accId) acc.value = incomeAccounts[i].title
			}
			for (let i = 0; i < expenseAccounts.length; i++) {
				if (expenseAccounts[i].value === accId) acc.value = expenseAccounts[i].title
			}
			r.push(acc);

			return r;
		} catch (e) {
			alert(e);
		}
	},

	/**
	 * The most right total of the simple row
	 * @param cmp
	 * @param rowKey unique Id of income or expense row
	 * @param type - income or expense
	 */
	helpCalculateRow: function (cmp, rowKey, type) {
		let rows = cmp.get("v." + type + "Data");
		let rowFound = false;
		for (let i = rows.length; i--;){
			if (rows[i].key === rowKey){
				this.helpSumRow(rows[i].rowValues);
				rowFound = true;
			}
		}
		if(rowFound) cmp.set("v." + type + "Data", rows);
		else{
			let grantRows = type === 'income' ? cmp.get('v.grantIncomeData') : cmp.get('v.grantExpenseData');
			for(let i = 0; i < grantRows.length; i++){
				for(let j = 0; j < grantRows[i][1].length; j++){
					if(grantRows[i][1][j].key === rowKey){
						this.helpSumRow(grantRows[i][1][j].rowValues);
						cmp.set('v.grant' + (type === 'income' ? 'Income' : 'Expense') + 'Data', grantRows);
						break;
					}
				}
			}
		}
		/*//(expense||income)TopDownSubData
		let rowsTD = cmp.get("v." + type + "TopDownSubData");
		for (let i = rowsTD.length; i--;) if (rowsTD[i].key === rowKey) this.helpSumRow(rowsTD[i].rowValues);
		cmp.set("v." + type + "TopDownSubData", rowsTD);*/
	},

	/**
	 *
	 * @param a rowValues
	 */
	helpSumRow: function (a) {
		try {
			let mt = 0; // money total
			let qt = 0; // quantity total
			let pt = 0; // price total
			for (let i = 0; i < a.length - 1; i++) {
				if (a[i].v !== '') mt += a[i].v - 0.0;
				if (a[i].q !== '') qt += a[i].q - 0.0;
				if (a[i].p !== '') pt += a[i].p - 0.0;
			}
			a[a.length - 1].v = mt;
			a[a.length - 1].q = qt;
			a[a.length - 1].p = pt;
			a[a.length - 1].t = 'disabled'; // t = type, total column disabling
		} catch (e) {
			alert(e);
		}
	},

	helpCalulateGrantTotals: function(cmp, type) {
		let getterStr = 'v.grant' + (type === 'income' ? 'Income' : 'Expense') + 'Data';
		let grantRows = cmp.get(getterStr);
		for(let i = 0; i < grantRows.length; i++){
			for(let z = 0; z < grantRows[i][1][0].rowValues.length; z++){
				grantRows[i][1][0].rowValues[z].v = 0;
			}
			for(let j = 1; j < grantRows[i][1].length; j++){
				for(let k = 0; k < grantRows[i][1][0].rowValues.length; k++){
					grantRows[i][1][0].rowValues[k].v += parseFloat(grantRows[i][1][j].rowValues[k].v);
				}
			}
		}
		cmp.set(getterStr, grantRows);
	},

	/**
	 * Top income and expense totals
	 * @param cmp
	 * @param type income || expense
	 */
	helpCalculateTotalRows: function (cmp, type) {
		try {
			type = type.toLowerCase();
			const arrInx = type === 'income' ? 0 : 1;
			let totals = cmp.get("v.totalData");
			let totalRow = totals[arrInx]; // selected total row

			let rows = cmp.get("v." + type + "Data");
			let grantRows = JSON.parse(JSON.stringify(cmp.get('v.grant' + (type === 'income' ? 'Income' : 'Expense') + 'Data')));
			if(grantRows !== undefined && grantRows !== null && grantRows.length !== 0) {
				for (let er = 0; er < grantRows.length; er++) {
					grantRows[er][1].shift();
					rows = rows.concat(grantRows[er][1]);
				}
			}
			rows = rows.concat(cmp.get("v." + type + "DownUpSubData"));
			rows = rows.concat(cmp.get("v." + type + "TopDownSubData"));
			//if (rows.length === 0) return;

			let totalValues = [];
			if (rows.length === 0) for (let i = totalRow.rowValues.length; i--;) totalValues[i] = {v: 0}; // last line deleted
			for (let i = rows.length; i--;) {
				const values = rows[i].rowValues;
				values[0].rowTotal = values[values.length - 1].v;
				for (let j = 0; j < values.length; j++) { // "j" is table column
					if (totalValues[j]) {
						totalValues[j].v = parseFloat(totalValues[j].v) + parseFloat(values[j].v);
					} else {
						totalValues[j] = JSON.parse(JSON.stringify(values[j])); // the first row
					}
				}
			}
			totalRow.rowValues = totalValues;
			totals[arrInx] = totalRow; // income is first, expense is second
			totals = this.helpSetDisableInputs(totals); // In Bottom-Up mode total inputs must be disabled
			cmp.set("v.totalData", totals);
		} catch (e) {
			alert('helpCalculateTotalRows=' + e);
		}
	},
	helpCalculateMarginRow: function (cmp) {
		if (this.isTopDown(cmp)) return null; // bottom-up only
		let totals = cmp.get("v.totalData");
		let template = cmp.get("v.template");
		if (template.cb4__Boolean2__c == false || template.cb4__Boolean3__c == false) return null; // income and expense sections only
		try {
			let expenseTotalValues = totals[1].rowValues;
			let marginTotals = JSON.parse(JSON.stringify(totals[0]));
			marginTotals.title = _isInvalid(template.cb4__Text5__c) ? 'margin' : template.cb4__Text5__c;
			marginTotals.ie = 'margin';
			for (let i = marginTotals.rowValues.length; i--;) marginTotals.rowValues[i].v -= expenseTotalValues[i].v;
			totals[2] = marginTotals;
			cmp.set("v.totalData", totals);
		} catch (e) {
			alert('helpCalculateMarginRow' + e);
		}
	},
	/**
	 * The method is for top-down mode only. Top-down mode can use only Income or Expense part
	 * @param cmp
	 * @param type  'income' OR 'expense'
	 */
	helpCalculateTargetTotalRows: function (cmp, type) {
		try {
			if (!this.isTopDown(cmp)) return null; // top-down only
			type = type.toLowerCase();
			const arrInx = type === 'income' ? 0 : 3;
			const totalInx = type === 'income' ? 0 : 1;
			let totals = cmp.get("v.totalData");
			let targetTotals = cmp.get("v.targetTotalData");
			let totalRow = totals[totalInx].rowValues; //EXPENSE Total
			let targetTotalRow = targetTotals[arrInx].rowValues; // BUDGETED EXPENSES Total
			let remainingRow = targetTotals[arrInx + 1].rowValues; // REMAINING EXPENSES Total
			let remainingBTDRow = targetTotals[arrInx + 2].rowValues; // REMAINING EXPENSES YTD Total
			let sum = 0;
			const len = targetTotalRow.length;
			for (let i = 0; i < len; i++) {
				remainingRow[i].v = targetTotalRow[i].v - totalRow[i].v - 0.0;
				if (i < len - 1) sum = sum + remainingRow[i].v;
				remainingBTDRow[i].v = sum;
			}
			cmp.set("v.targetTotalData", targetTotals);
		} catch (e) {
			alert(" helpCalculateTargetTotalRows=" + e);
		}
	}
	,

	/**
	 * Calculated(Synthetic) row to simple
	 * if key === null, all rows will be converted to simple rows
	 */
	helpConvertToSimpleRow: function (cmp, key) {
		let income = cmp.get("v.incomeData");
		let expense = cmp.get("v.expenseData");
		for (let i = 0; i < income.length; i++) if (_isInvalid(key) || income[i].key === key) {
			income[i].styleClass = '';
			this.helpSetEnableInputs([income[i]]);
		}
		for (let i = 0; i < expense.length; i++) if (_isInvalid(key) || expense[i].key === key) {
			expense[i].styleClass = '';
			this.helpSetEnableInputs([expense[i]]);
		}
		cmp.set("v.incomeData", income);
		cmp.set("v.expenseData", expense);
	},

	helpDeleteRow: function (cmp, key) {
		let income = cmp.get("v.incomeData");
		let grantIncome = cmp.get("v.grantIncomeData");
		let expense = cmp.get("v.expenseData");
		let grantExpense = cmp.get("v.grantExpenseData");

		let newIncome = [];
		let newGrantIncome = [];
		let newExpense = [];
		let newGrantExpense = [];

		for (let i = 0; i < income.length; i++) if (!(income[i].key === key)) newIncome.push(income[i]);
		for (let i = 0; i < expense.length; i++) if (!(expense[i].key === key)) newExpense.push(expense[i]);
		for(let gKey in grantIncome) {
			newGrantIncome[gKey] = [grantIncome[gKey][0], [grantIncome[gKey][1][0]]];
			for (let i = 1; i < grantIncome[gKey][1].length; i++)
				if (!(grantIncome[gKey][1][i].key === key)){
					newGrantIncome[gKey][1].push(grantIncome[gKey][1][i]);
				}else{
					for(let gi = 0; gi < newGrantIncome[gKey][1][0].rowValues.length; gi++)
					newGrantIncome[gKey][1][0].rowValues[gi].v -= parseFloat(grantIncome[gKey][1][i].rowValues[gi].v);
				}
		}
		for(let gKey in grantExpense) {
			newGrantExpense[gKey] = [grantExpense[gKey][0], [grantExpense[gKey][1][0]]];
			for (let i = 1; i < grantExpense[gKey][1].length; i++)
				if (!(grantExpense[gKey][1][i].key === key)){
					newGrantExpense[gKey][1].push(grantExpense[gKey][1][i]);
				}else{
					for(let gi = 0; gi < newGrantExpense[gKey][1][0].rowValues.length; gi++)
						newGrantExpense[gKey][1][0].rowValues[gi].v -= parseFloat(grantExpense[gKey][1][i].rowValues[gi].v);
				}
		}

		cmp.set("v.incomeData", newIncome);
		cmp.set("v.grantIncomeData", newGrantIncome);
		cmp.set("v.expenseData", newExpense);
		cmp.set("v.grantExpenseData", newGrantExpense);

		this.helpCalculateTotalRows(cmp, 'income');
		this.helpCalculateTotalRows(cmp, 'expense');
		this.helpCalculateMarginRow(cmp); // calculate margin / difference
		this.helpCalculateTargetTotalRows(cmp, 'income');
		this.helpCalculateTargetTotalRows(cmp, 'expense');

		this.helpSetBackup(cmp, 'Line was deleted');
	},

	helpGetAppNavigation: function (cmp) {
		let action = cmp.get("c.getAppNavigationServer");
		action.setParams({
			"appId": cmp.get("v.app.Id")
		});
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				try {
					let navMap = response.getReturnValue();
					let tmp = [];
					for (let key in navMap) tmp.push({value: navMap[key], key: key});
					cmp.set("v.navigationStrings", tmp);
				} catch (e) {
					alert(e);
				}
			} else {
				_CBMessages.fireErrorMessage(_TEXT.APPS.FAILED_APP_NAVIGATION);
			}
		});
		$A.enqueueAction(action);
	},

	helpGetAllSOMap: function (cmp) {
		let allSO = cmp.get("v.incomeAccountsSO");
		allSO = allSO.concat(cmp.get("v.expenseAccountsSO"));
		allSO = allSO.concat(cmp.get("v.d6SO"));
		allSO = allSO.concat(cmp.get("v.d7SO"));
		allSO = allSO.concat(cmp.get("v.d8SO"));
		allSO = allSO.concat(cmp.get("v.d9SO"));
		allSO = allSO.concat(cmp.get("v.d10SO"));
		let allSOMap = {};
		for (let i = allSO.length; i--;) allSOMap[allSO[i].value] = allSO[i].title;
		return allSOMap;
	},

	/**
	 * The method updates each line details (show more)
	 * @param cmp
	 */
	helpTitleRows: function (cmp) {

		const allSOMap = this.helpGetAllSOMap(cmp);

		let incomeRows = cmp.get("v.incomeData");
		let grantIncome = cmp.get('v.grantIncomeData')
		let expenseRows = cmp.get("v.expenseData");
		let grantExpense = cmp.get('v.grantExpenseData');

		function setTitles(row){
            row.accT = allSOMap[row.account];
            if (!_isInvalid(row.dim6)) row.dim6T = allSOMap[row.dim6]; else delete row.dim6T;
            if (!_isInvalid(row.dim7)) row.dim7T = allSOMap[row.dim7]; else delete row.dim7T;
            if (!_isInvalid(row.dim8)) row.dim8T = allSOMap[row.dim8]; else delete row.dim8T;
            if (!_isInvalid(row.dim9)) row.dim9T = allSOMap[row.dim9]; else delete row.dim9T;
            if (!_isInvalid(row.dim10)) row.dim10T = allSOMap[row.dim10]; else delete row.dim10T;
		}

		for (let i = incomeRows.length; i--;) {
			setTitles(incomeRows[i]);
		}

		for (let i = expenseRows.length; i--;) {
            setTitles(expenseRows[i]);
		}

		for(let i = 0; i < grantIncome.length; i++){
			for(let j = 1; j < grantIncome[i][1].length; j++){
				setTitles(grantIncome[i][1][j]);
			}
		}

		for(let i = 0; i < grantExpense.length; i++){
            for(let j = 1; j < grantExpense[i][1].length; j++){
				setTitles(grantExpense[i][1][j]);
            }
		}

		cmp.set("v.incomeData", incomeRows);
		cmp.set("v.grantIncomeData", grantIncome);
		cmp.set("v.expenseData", expenseRows);
		cmp.set("v.grantExpenseData", grantExpense);
	},

	helpCheckIfApproveAllowed: function (cmp) {
		_CBRequest(cmp, "c.checkIfApprovingAllowedServer", {'appId': cmp.get("v.app.Id")}, "v.approvingIsAllowed", null, null, null);
	}
	,

/////// NAVIGATION ///////
	helpBackToMainTable: function (cmp) {
		function redirectToList() {
			_CBRedirect.toComponent("c:CBBudgetApplication", {mode: 'table'});
		}

		this.helpApproveSavingAndRedirect(cmp, redirectToList);
	},
	helpRedirectToAppSheet: function (cmp, doDownloadExcelOnload) {
		function redirectToAppSheet() {
			_CBRedirect.toComponent('c:CBBudgetApplicationSheet', {'recordId': cmp.get("v.app.Id"), 'doDownloadExcelOnload': doDownloadExcelOnload});
		}

		this.helpApproveSavingAndRedirect(cmp, redirectToAppSheet);
	},
	/**
	 * @param redirectFunc - callback function after saving
	 */
	helpApproveSavingAndRedirect: function (cmp, redirectFunc) {
		if (cmp.get("v.needSave")) {
			if (confirm(_TEXT.APPS.REDIRECT_CONFIRM)) {
				this.helpSaveApp(cmp, redirectFunc);
			} else {
				redirectFunc();
			}
		} else {
			redirectFunc();
		}
	},
	/////// NAVIGATION ///////

	/////// EXCEL ///////
	/**
	 * DOWNLOAD EXCEL FILE
	 * @param cmp
	 */
	helpDownloadExcel: function (cmp, aim) {
		//console.clear();
		try {
			let subLinesRequireAdditionalWarning =
				(cmp.get("v.incomeDownUpSubData")).length > 0 ||
				(cmp.get("v.incomeTopDownSubData")).length > 0 ||
				(cmp.get("v.expenseDownUpSubData")).length > 0 ||
				(cmp.get("v.expenseTopDownSubData")).length > 0;
			if (subLinesRequireAdditionalWarning)
				if (confirm("Note that consolidated and sub-consolidated budgets should be exported to Excel from Budget Sheet view. \n " +
					"Pressing OK will lead you to this view from this budget. " +
					"You will need to use Export to Excel option from there.")) {
					this.helpRedirectToAppSheet(cmp, true);
					return null;
				}

		} catch (e) {

		}

		try {
			// PREPARATION
			let exStyle = this.getExcelStyle(); // styles
			// excel columns map
			let abc = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'AA', 'AB'];

			// Accounts
			let accounts = {};
			let incAcc = cmp.get("v.incomeAccountsSO");
			let expAcc = cmp.get("v.expenseAccountsSO");
			let incAccArray = '';
			let expAccArray = '';
			for (let j = 0; j < incAcc.length; j++) {
				accounts[incAcc[j].value] = incAcc[j].title;
				incAccArray += incAcc[j].title.replace(/,/g, '⸴') + ',';
			}
			for (let j = 0; j < expAcc.length; j++) {
				accounts[expAcc[j].value] = expAcc[j].title;
				expAccArray += expAcc[j].title.replace(/,/g, '⸴') + ',';
			}
			// Accounts

			// Dimension
			let dim6 = {};
			let dim7 = {};
			let dim8 = {};
			let dim9 = {};
			let dim10 = {};
			let dim6Array = '';
			let dim7Array = '';
			let dim8Array = '';
			let dim9Array = '';
			let dim10Array = '';
			let d6SO = cmp.get('v.d6SO');
			let d7SO = cmp.get('v.d7SO');
			let d8SO = cmp.get('v.d8SO');
			let d9SO = cmp.get('v.d9SO');
			let d10SO = cmp.get('v.d10SO');

			let d6Name = cmp.get('v.d6name');
			let d7Name = cmp.get('v.d7name');
			let d8Name = cmp.get('v.d8name');
			let d9Name = cmp.get('v.d9name');
			let d10Name = cmp.get('v.d10name');

			let text6 = cmp.get('v.Text6__c');
			let text7 = cmp.get('v.Text7__c');
			let text8 = cmp.get('v.Text8__c');
			let text9 = cmp.get('v.Text9__c');

			let decimal6 = cmp.get('v.Decimal6__c');
			let decimal7 = cmp.get('v.Decimal7__c');
			let decimal8 = cmp.get('v.Decimal8__c');
			let decimal9 = cmp.get('v.Decimal9__c');
			let decimal10 = cmp.get('v.Decimal10__c');

			for (let j = 0; j < d6SO.length; j++) {
				dim6[d6SO[j].value] = d6SO[j].title;
				dim6Array += d6SO[j].title.replace(/,/g, '⸴') + ',';
			}
			for (let j = 0; j < d7SO.length; j++) {
				dim7[d7SO[j].value] = d7SO[j].title;
				dim7Array += d7SO[j].title.replace(/,/g, '⸴') + ',';
			}
			for (let j = 0; j < d8SO.length; j++) {
				dim8[d8SO[j].value] = d8SO[j].title;
				dim8Array += d8SO[j].title.replace(/,/g, '⸴') + ',';
			}
			for (let j = 0; j < d9SO.length; j++) {
				dim9[d9SO[j].value] = d9SO[j].title;
				dim9Array += d9SO[j].title.replace(/,/g, '⸴') + ',';
			}
			for (let j = 0; j < d10SO.length; j++) {
				dim10[d10SO[j].value] = d10SO[j].title;
				dim10Array += d10SO[j].title.replace(/,/g, '⸴') + ',';
			}
			// Dimension

			// data
			let income = cmp.get("v.incomeData");
			let expense = cmp.get("v.expenseData");
			let grantIncome = cmp.get('v.grantIncomeData');
			let grantExpense = cmp.get('v.grantExpenseData');
			for(let i = 0; i < grantIncome.length; i++){
				grantIncome[i][1].shift();
				income = income.concat(grantIncome[i][1]);
			}
			for(let i = 0; i < grantExpense.length; i++){
				grantExpense[i][1].shift();
				expense = expense.concat(grantExpense[i][1]);
			}

			let template = cmp.get("v.template");
			if (template.cb4__Boolean2__c && income.length === 0) income = this.helpAddEmptyLines(cmp, income, 'income');
			if (template.cb4__Boolean3__c && expense.length === 0) expense = this.helpAddEmptyLines(cmp, expense, 'expense');
			let tableHeaders = cmp.get("v.headers");
			// data

			let workbook = new ExcelJS.Workbook();
			let sheetName = cmp.get('v.app.cb4__TagLabel__c');
			let worksheet = workbook.addWorksheet('APP', {
				views: [
					{state: 'frozen', ySplit: 1, xSplit: 0}
				],
				properties: {showGridLines: true}
			});

			// TABLE COLUMNS
			let columns = [];
			columns.push({header: 'Type', key: 'type', width: 8});// 1
			columns.push({header: 'Title', key: 'title', width: 28}); // 2
			columns.push({header: 'Account', key: 'acc', width: 23}); // 3
			columns.push({header: 'Description', key: 'desc', width: 23}); //4

			if (d6Name != null) columns.push({header: d6Name, key: 'd6', width: 23}); //5?
			if (d7Name != null) columns.push({header: d7Name, key: 'd7', width: 23}); //6?
			if (d8Name != null) columns.push({header: d8Name, key: 'd8', width: 23}); //7?
			if (d9Name != null) columns.push({header: d9Name, key: 'd9', width: 23}); //8?
			if (d10Name != null) columns.push({header: d10Name, key: 'd10', width: 23}); //9?

			if (text6 != null) columns.push({header: text6, key: 'txt6', width: 23}); //10?
			if (text7 != null) columns.push({header: text7, key: 'txt7', width: 23}); //11?
			if (text8 != null) columns.push({header: text8, key: 'txt8', width: 23}); //12?
			if (text9 != null) columns.push({header: text9, key: 'txt9', width: 23}); //13?

			if (decimal6 != null) columns.push({header: decimal6, key: 'dec6', width: 23}); //14?
			if (decimal7 != null) columns.push({header: decimal7, key: 'dec7', width: 23}); //15?
			if (decimal8 != null) columns.push({header: decimal8, key: 'dec8', width: 23}); //16?
			if (decimal9 != null) columns.push({header: decimal9, key: 'dec9', width: 23}); //17?
			if (decimal10 != null) columns.push({header: decimal10, key: 'dec10', width: 23}); //18?

			columns.push({header: '#', key: 'idx', width: 3}); // index column (can be 5th up to 10th)
			let numberOfColumns = 0;// number of value columns (4-12)
			tableHeaders.forEach(function (h) {
				numberOfColumns++;
				columns.push({header: h, key: h, width: 14, style: {numFmt: '$ #,##0.00;[Red]($ #,##0.00)'}}); // simple columns with amounts
			});
			columns.push({ // row total column
				header: 'Total',
				key: 'total',
				width: 15,
				style: {numFmt: '$ #,##0.00;[Red]($ #,##0.00)'}
			});
			worksheet.columns = columns;

			worksheet.getColumn(worksheet.actualColumnCount).font = exStyle.totalFont; // total column style (.actualColumnCount is number of columns in the row)
			//worksheet.getColumn(1).hidden = true; // Hide first column
			// TABLE COLUMNS

			// COLUMNS CALCULATIONS
			let startTotalPosition = 5; // index of the first value column
			if (d6Name != null) startTotalPosition++;
			if (d7Name != null) startTotalPosition++;
			if (d8Name != null) startTotalPosition++;
			if (d9Name != null) startTotalPosition++;
			if (d10Name != null) startTotalPosition++;
			if (text6 != null) startTotalPosition++;
			if (text7 != null) startTotalPosition++;
			if (text8 != null) startTotalPosition++;
			if (text9 != null) startTotalPosition++;
			if (decimal6 != null) startTotalPosition++;
			if (decimal7 != null) startTotalPosition++;
			if (decimal8 != null) startTotalPosition++;
			if (decimal9 != null) startTotalPosition++;
			if (decimal10 != null) startTotalPosition++;
			let endTotalPosition = startTotalPosition + numberOfColumns - 1; // index of the last value column for row total
			startTotalPosition = abc[startTotalPosition];// column 'E' for example
			endTotalPosition = abc[endTotalPosition];// column 'T' for example
			// COLUMNS CALCULATIONS

			// TABLE ROWS
			let i = 0; // index of the row

			function fillExcelLines(type, lines, fillStyle, accountSO) {
				if (lines.length > 0) lines.forEach(function (line) { // line  - is a Budget App line
					let r = {}; // one row

					r['type'] = type; // the first column
					r['title'] = _isInvalid(line.title) ? 'General' : line.title; // the second column
					r['title'] = line['styleClass'] === 'calcRule' ? 'Ⓕ ' + r['title'] : r['title']; // FORMULA ROW
					r['acc'] = accounts[line.account]; // the third column
					r['desc'] = _isInvalid(line.description) ? ' ' : line.description; // the 4-th column
					r['d6'] = _isInvalid(dim6[line.dim6]) ? null : dim6[line.dim6].replace(/,/g, '⸴');
					r['d7'] = _isInvalid(dim7[line.dim7]) ? null : dim7[line.dim7].replace(/,/g, '⸴');
					r['d8'] = _isInvalid(dim8[line.dim8]) ? null : dim8[line.dim8].replace(/,/g, '⸴');
					r['d9'] = _isInvalid(dim9[line.dim9]) ? null : dim9[line.dim9].replace(/,/g, '⸴');
					r['d10'] = _isInvalid(dim10[line.dim10]) ? null : dim10[line.dim10].replace(/,/g, '⸴');

					r['txt6'] = _isInvalid(line.text6) ? null : (line.text6 + '').replace(/,/g, '⸴');
					r['txt7'] = _isInvalid(line.text7) ? null : (line.text7 + '').replace(/,/g, '⸴');
					r['txt8'] = _isInvalid(line.text8) ? null : (line.text8 + '').replace(/,/g, '⸴');
					r['txt9'] = _isInvalid(line.text9) ? null : (line.text9 + '').replace(/,/g, '⸴');

					r['dec6'] = _isInvalid(line.decimal6) ? null : line.decimal6;
					r['dec7'] = _isInvalid(line.decimal7) ? null : line.decimal7;
					r['dec8'] = _isInvalid(line.decimal8) ? null : line.decimal8;
					r['dec9'] = _isInvalid(line.decimal9) ? null : line.decimal9;
					r['dec10'] = _isInvalid(line.decimal10) ? null : line.decimal10;

					r['idx'] = ++i;
					for (let j = 0; j < tableHeaders.length; j++) r[tableHeaders[j]] = parseFloat(line.rowValues[j]['v']);

					const k = i + 1; // row index to calculate the totals

					r['total'] = {formula: 'SUM(' + startTotalPosition + k + ':' + endTotalPosition + k + ')'}; // formula example SUM(J5:U5)
					worksheet.addRow(r);

					worksheet.getRow(k).getCell(3).dataValidation = {
						type: 'list',
						allowBlank: false,
						formulae: [accountSO] //=Service!$A$1:$A$18  A if Income and B if Expense
					};
					let dimIdx = 5;
					if (d6Name != null && d6SO.length > 0) worksheet.getRow(k).getCell(dimIdx++).dataValidation = {
						type: 'list',
						allowBlank: true,
						formulae: ['Service!$C$1:$C$' + d6SO.length]
					};
					if (d7Name != null && d7SO.length > 0) worksheet.getRow(k).getCell(dimIdx++).dataValidation = {
						type: 'list',
						allowBlank: true,
						formulae: ['Service!$D$1:$D$' + d7SO.length]
					};
					if (d8Name != null && d8SO.length > 0) worksheet.getRow(k).getCell(dimIdx++).dataValidation = {
						type: 'list',
						allowBlank: true,
						formulae: ['Service!$E$1:$E$' + d8SO.length]
					};
					if (d9Name != null && d9SO.length > 0) worksheet.getRow(k).getCell(dimIdx++).dataValidation = {
						type: 'list',
						allowBlank: true,
						formulae: ['Service!$F$1:$F$' + d9SO.length]
					};
					if (d10Name != null && d10SO.length > 0) worksheet.getRow(k).getCell(dimIdx++).dataValidation = {
						type: 'list',
						allowBlank: true,
						formulae: ['Service!$G$1:$G$' + d10SO.length]
					};
					worksheet.getRow(k).eachCell({includeEmpty: true}, function (cell, colNumber) {
						cell.fill = fillStyle;
						cell.border = exStyle.simpleBorders;
						cell.font = line['styleClass'] === 'calcRule' ? {color: {argb: "7c7c7c"}} : {color: {argb: "101312"}};
					});
				});
			}

			fillExcelLines('Income', income, exStyle.incomeFill, 'Service!$A$1:$A$' + incAcc.length);
			fillExcelLines('Expense', expense, exStyle.expenseFill, 'Service!$B$1:$B$' + expAcc.length);

			worksheet.getRow(1).eachCell({includeEmpty: true}, function (cell, cellNumber) { // header
				cell.font = exStyle.headerFont;
				cell.border = exStyle.headerBorder;
				cell.fill = exStyle.headerFill;
			});

			// index column
			worksheet.getColumn('idx').fill = exStyle.headerFill;
			worksheet.getColumn('idx').font = exStyle.headerFont;
			// TABLE ROWS

			//////////////////////////// SECOND SHEET
			// DETAILS SHEET
			let secondSheet = workbook.addWorksheet('Details', {properties: {tabColor: {argb: '699be1'}}});
			secondSheet.getColumn(1).width = 30;
			secondSheet.getColumn(2).width = 100;
			secondSheet.addRow(['Title:', cmp.get('v.app.cb4__TagLabel__c')]);
			secondSheet.addRow(['Description:', cmp.get('v.app.cb4__Text3__c')]);
			secondSheet.addRow(['Parent:', cmp.get('v.app.cb4__Tag1Name__c')]);
			secondSheet.addRow(['Template:', cmp.get('v.app.cb4__Tag2Name__c')]);
			secondSheet.addRow(['Period:', cmp.get('v.app.cb4__Tag3Name__c')]);
			secondSheet.addRow(['Department:', cmp.get('v.app.cb4__Tag4Name__c')]);

			const appDim6name = cmp.get('v.appDim6name');
			const tag6name = cmp.get('v.app.cb4__Tag6Name__c');
			const appDim7name = cmp.get('v.appDim7name');
			const tag7name = cmp.get('v.app.cb4__Tag7Name__c');
			const appDim8name = cmp.get('v.appDim8name');
			const tag8name = cmp.get('v.app.cb4__Tag8Name__c');
			const appDim9name = cmp.get('v.appDim9name');
			const tag9name = cmp.get('v.app.cb4__Tag9Name__c');
			const appDim10name = cmp.get('v.appDim10name');
			const tag10name = cmp.get('v.app.cb4__Tag10Name__c');
			if (!(_isInvalid(appDim6name) || _isInvalid(tag6name))) secondSheet.addRow([appDim6name + ': ', tag6name]);
			if (!(_isInvalid(appDim7name) || _isInvalid(tag7name))) secondSheet.addRow([appDim7name + ': ', tag7name]);
			if (!(_isInvalid(appDim8name) || _isInvalid(tag8name))) secondSheet.addRow([appDim8name + ': ', tag8name]);
			if (!(_isInvalid(appDim9name) || _isInvalid(tag9name))) secondSheet.addRow([appDim9name + ': ', tag9name]);
			if (!(_isInvalid(appDim10name) || _isInvalid(tag10name))) secondSheet.addRow([appDim10name + ': ', tag10name]);

			secondSheet.addRow([]);
			secondSheet.addRow([]);
			secondSheet.addRow(['CloudBudget 2.0']);
			secondSheet.addRow([new Date().toJSON().slice(0, 10).replace(/-/g, '/')]);
			// DETAILS SHEET

			//THIRD SHEET
			let thirdSheet = workbook.addWorksheet('Service', {properties: {tabColor: {argb: '699be1'}}});
			thirdSheet.getColumn(1).values = incAccArray.split(",");
			thirdSheet.getColumn(2).values = expAccArray.split(",");
			thirdSheet.getColumn(3).values = dim6Array.split(",");
			thirdSheet.getColumn(4).values = dim7Array.split(",");
			thirdSheet.getColumn(5).values = dim8Array.split(",");
			thirdSheet.getColumn(6).values = dim9Array.split(",");
			thirdSheet.getColumn(7).values = dim10Array.split(",");
			//THIRD SHEET

			// DETAILS STYLE
			secondSheet.getColumn(1).fill = exStyle.detailsHeaderFill;
			secondSheet.getColumn(1).font = exStyle.totalFont;
			// DETAILS STYLE

			let file;

			function createFile(blob) {
				file = blob;
				file.name = cmp.get('v.app.cb4__TagLabel__c') + '.xlsx';
			}

			function uploadFile() {
				let googleDriveComp = cmp.find('googleDrive');
				cmp.set('v.uploadedFile', file);
				googleDriveComp.uploadFile();
			}

			switch (aim) {
				case 'GoogleDisk':
					workbook.xlsx.writeBuffer().then(buffer => createFile(new Blob([buffer]))).then(pr => uploadFile()).catch(err => alert('Error writing excel export' + err));
					break;
				case 'ExcelFile':
					workbook.xlsx.writeBuffer().then(buffer => saveAs(new Blob([buffer]), cmp.get('v.app.cb4__TagLabel__c') + '.xlsx')).catch(err => alert('Error writing excel export' + err));
					break;
				case 'PDF':
					break;
				default:
					_cl("So what?", "orange");
			}
		} catch (e) {
			alert(e)
		}
	},

	helpAddEmptyLines: function (cmp, lines, type) {
		try {
			type = type.toLowerCase();
			let accountSO = type === 'income' ? cmp.get('v.incomeAccountsSO') : cmp.get('v.expenseAccountsSO');
			let newLine = JSON.parse(JSON.stringify(cmp.get("v.totalData")[0])); // sample

			for (let i = newLine.rowValues.length; i--;) newLine.rowValues[i] = {"v": 0, "q": 0, "p": 0}; // zeroing column values
			newLine.rowValues[0] = {"v": 1, "q": 0, "p": 0};
			newLine.rowValues[0].rowTotal = 0; // line total
			newLine.rowValues[newLine.rowValues.length - 1].t = 'disabled'; // disable total column
			newLine.key = Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);// add unique index
			newLine.title = newLine.title != null && newLine.title.length > 0 ? accountSO[0].title : _TEXT.APPS.NEW_LINE_TITLE; // adding title like the first account
			newLine.account = _isInvalid(newLine.account) ? accountSO[0].value : newLine.account; // add account Id
			newLine.description = "⚠ Pattern Line";
			newLine.ie = type;
			lines.push(newLine);
		} catch (e) {
			alert(e);
		}
		return lines;
	},

	getExcelStyle: function () {
		let r = {};
		r.headerFill = {
			type: 'pattern',
			pattern: 'solid',
			fgColor: {argb: '699be1'}
		};
		r.headerFont = {bold: true, color: {argb: 'FFFFFF'}}; // white bold
		r.totalFont = {bold: true, color: {argb: '000000'}}; // black bold
		r.incomeFill = {
			type: 'pattern',
			pattern: 'solid',
			fgColor: {argb: 'd3f6db'}
		};
		r.expenseFill = {
			type: 'pattern',
			pattern: 'solid',
			fgColor: {argb: 'd2bebd'}
		};
		r.simpleBorders = {
			top: {style: "thin"},
			left: {style: "thin"},
			bottom: {style: "thin"},
			right: {style: "thin"}
		};
		r.headerBorder = {
			top: {style: "thin"},
			left: {style: "thin"},
			bottom: {style: 'double', color: {argb: '005493'}},
			right: {style: "thin"}
		};
		r.detailsHeaderBorder = {
			top: {style: "thin"},
			left: {style: "thin"},
			bottom: {style: 'double', color: {argb: '005493'}},
			right: {style: "thin"}
		};
		r.detailsHeaderFill = {
			type: 'pattern',
			pattern: 'solid',
			fgColor: {argb: 'd2bebd'}
		};
		return r;
	},

	/**
	 * UPLOAD EXCEL FILE
	 * @param cmp
	 * @param workbook
	 */
	helpApplyExcelFile: function (cmp, workbook) {
		console.clear();
		_cl('Excel file uploading', 'green');

		try {
			let income = [];
			let expense = [];
			let reportMessages = [];
			let errorMessages = [];
			let success = 0;
			let errors = 0;
			let iconType = "action:approval";

			let incAcc = cmp.get("v.incomeAccountsSO");
			let expAcc = cmp.get("v.expenseAccountsSO");
			let d6SO = cmp.get('v.d6SO');
			let d7SO = cmp.get('v.d7SO');
			let d8SO = cmp.get('v.d8SO');
			let d9SO = cmp.get('v.d9SO');
			let d10SO = cmp.get('v.d10SO');

			let analyticOrder = [];
			if (cmp.get('v.d6name') != null) analyticOrder.push('dim6');
			if (cmp.get('v.d7name') != null) analyticOrder.push('dim7');
			if (cmp.get('v.d8name') != null) analyticOrder.push('dim8');
			if (cmp.get('v.d9name') != null) analyticOrder.push('dim9');
			if (cmp.get('v.d10name') != null) analyticOrder.push('dim10');
			if (cmp.get('v.Text6__c') != null) analyticOrder.push('text6');
			if (cmp.get('v.Text7__c') != null) analyticOrder.push('text7');
			if (cmp.get('v.Text8__c') != null) analyticOrder.push('text8');
			if (cmp.get('v.Text9__c') != null) analyticOrder.push('text9');
			if (cmp.get('v.Decimal6__c') != null) analyticOrder.push('dec6');
			if (cmp.get('v.Decimal7__c') != null) analyticOrder.push('dec7');
			if (cmp.get('v.Decimal8__c') != null) analyticOrder.push('dec8');
			if (cmp.get('v.Decimal9__c') != null) analyticOrder.push('dec9');
			if (cmp.get('v.Decimal10__c') != null) analyticOrder.push('dec10');

			_cl('Preparation is OK', 'green');

			let dataSheet = workbook.getWorksheet(1);// take the second tab
			reportMessages.push('Total number of rows: ' + (dataSheet.rowCount - 1));
			let rMap = dataSheet.getRow(1).values; // ['Type','Title','Account','Description','CB_FF1'.....'#','01/2020'....];

			let j = 0;
			// Accounts
			let accounts = {};
			let dimensions = {};
			try {
				for (j = incAcc.length; j--;) accounts[incAcc[j].title.replace(/,/g, '⸴')] = incAcc[j].value;
				for (j = expAcc.length; j--;) accounts[expAcc[j].title.replace(/,/g, '⸴')] = expAcc[j].value;

				for (j = d6SO.length; j--;) dimensions[d6SO[j].title.replace(/,/g, '⸴') + '6'] = d6SO[j].value;
				for (j = d7SO.length; j--;) dimensions[d7SO[j].title.replace(/,/g, '⸴') + '7'] = d7SO[j].value;
				for (j = d8SO.length; j--;) dimensions[d8SO[j].title.replace(/,/g, '⸴') + '8'] = d8SO[j].value;
				for (j = d9SO.length; j--;) dimensions[d9SO[j].title.replace(/,/g, '⸴') + '9'] = d9SO[j].value;
				for (j = d10SO.length; j--;) dimensions[d10SO[j].title.replace(/,/g, '⸴') + '10'] = d10SO[j].value;
			} catch (e) {
				alert('replace 1: ' + e)
			}

			// Accounts


			// Dimensions


			// Dimensions
			_cl('Initialization is OK', 'green');


			let dims, values, reachValues, reachTotal, dimNumber, numberOfCells, errorMessage, type, title, accName,
				description,
				accId, val, dimId, key, appRow, rowValues, total, exIdx, k, v, texts, decimals, textNumber,
				decimalNumber, analyticIndex;

			dataSheet.eachRow(function (row, rowNumber) { // iteration over the lines
				if (rowNumber === 1) return true; // file header
				errorMessage;
				type = row.getCell(1).value;
				if (_isInvalid(type) || typeof type !=='string' || !type ) {
					errorMessages.push('Line ' + rowNumber + ' was ignored due to formatting. Line type is not specified');
					errors++;
					return true;
				}
				title = _isInvalid(row.getCell(2).value.result) ? row.getCell(2).value : row.getCell(2).value.result;
				try {
					accName = row.getCell(3).value.replace(/,/g, '⸴');
				} catch (e) {
					alert('replace 2: ' + e);
					_cl(rowNumber);
				}

				description = row.getCell(4).value;
				accId = accounts[accName];
				if (_isInvalid(accId)) {
					errorMessages.push('Row: ' + rowNumber + ' account  "' + accName + '" is invalid');
					errors++;
					return true;
				}
				dims = []; // array of dimensions
				texts = []; // array of texts
				decimals = []; // array of decimals
				values = []; // totals

				reachValues = false; // FLAG: Did the iteration reach the amount columns?
				reachTotal = false; // FLAG: Did the iteration reach the total column?
				dimNumber = 6; // start of dim6... dim10
				textNumber = 6; // start of dim6... dim10
				decimalNumber = 6; // start of dim6... dim10
				analyticIndex = 0;

				numberOfCells = row.cellCount; // total number of cells
				row.eachCell({includeEmpty: true}, function (cell, cellNumber) { // iteration over the cells
					if (cellNumber > 4) {// four first columns excluded
						if (rMap[cellNumber] === 'Total') { // index is the end of period columns
							reachTotal = true;
							return true; // skip "Total" column
						}
						if (rMap[cellNumber] === '#') { // index is the end of dimension columns and start of the amount columns
							reachValues = true;
							return true; // skip "#" column
						}
						if (numberOfCells === cellNumber || reachTotal) return true; // skip total cell
						if (reachValues) { // value columns managing
							if (_isInvalid(cell.value)) cell.value = 0;
							val = typeof cell.value === 'number' ? Math.round(cell.value) : Math.round(cell.value.result); // cell.value = 27  OR cell.value={"formula":"J3*2","result":24200}
							if (_isInvalid(val)) val = 0;
							values.push(val); // converting to float is below
						} else { // dimension columns
							let analyticType = analyticOrder[analyticIndex];
							if (analyticType.includes("dim")) {
								dimId = dimensions[cell.value + dimNumber]; // "dimension title + dimension number" is  the key for Dimension Map. Index needed because dimension titles can repeated in the different dimension types
								if (_isInvalid(dimId)) dimId = '';
								dims.push(dimId);
								dimNumber++;
							} else if (analyticType.includes("text")) {
								texts.push(cell.value);
							} else if (analyticType.includes("dec")) {
								if (!isNaN(cell.value)) decimals.push(cell.value);
							}
							analyticIndex++;
						}
					}
				});
				if (errorMessage != null) {
					errors++;
					errorMessages.push(errorMessage);
					return true;
				}

				key = accId;
				appRow = {
					'title': title,
					'account': accId
				};

				const isCalcLine = !_isInvalid(appRow.title) && appRow.title.includes('Ⓕ ');
				try {
					if (isCalcLine) {
						appRow.title = appRow.title.replace('Ⓕ ', '');
						appRow.styleClass = 'calcRule';
					}
				} catch (e) {
					alert('replace 3: ' + e)
				}


				rowValues = [];
				total = 0;
				for (k = 0; k < values.length; k++) {
					v = parseFloat(values[k]);
					rowValues.push({'v': v, 'p': 0, 'q': 0, 't': isCalcLine ? 'disabled' : false});
					total += parseFloat(v);
				}
				rowValues.push({'v': total, t: 'disabled'});
				appRow.rowValues = rowValues;
				appRow.ie = type.toLowerCase() === 'income' ? 'income' : 'expense';

				exIdx = 6;
				for (k = 0; k < dims.length; k++) {
					appRow['dim' + exIdx] = dims[k];
					key += dims[k];
					if (!_isInvalid(texts[k])) appRow['text' + exIdx] = texts[k];
					if (!_isInvalid(texts[k])) appRow['decimal' + exIdx] = decimals[k];
					exIdx++;
				}

				key = key + description;
				appRow.description = description;
				try {
					appRow.key = key.replace(/ /g, '').replace(':', '').replace('&', '').trim() + rowNumber + 'row';
				} catch (e) {
					alert('replace 4: ' + e)
				}


				if (type.toLowerCase() === 'income') {
					income.push(appRow);
				} else {
					expense.push(appRow);
				}
				success++;

			});

			_cl('Processing is OK', 'green');

			reportMessages.push('Rows successfully uploaded: ' + success);
			reportMessages.push('Rows not imported: ' + errors);
			if (errorMessages.length > 0) {
				reportMessages.push('------------------------------------------------------------------------------------');
				reportMessages.push('Issues found: ');
				for (let i = 0; i < errorMessages.length; i++) {
					reportMessages.push((i + 1) + '. ' + errorMessages[i]);
				}
			}


			if (errors > 0) iconType = "action:close";


			let _this = this;

			if (!confirm(_TEXT.APPS.UPDATE_TITLES_QUESTION)) {
				function applyTitle(row) {
					return _this.helpUpdateAppLineTitle(cmp, 'mass', row, false);
				}

				income = income.map(applyTitle);
				expense = expense.map(applyTitle);
			}

			cmp.set("v.incomeData", income);
			cmp.set("v.grantIncomeData", []);
			cmp.set("v.expenseData", expense);
			cmp.set("v.grantExpenseData", []);

			this.helpShowImportReport(cmp, reportMessages, iconType);
			this.helpCalculateTotalRows(cmp, 'income');
			this.helpCalculateTotalRows(cmp, 'expense');
			this.helpCalculateMarginRow(cmp); // calculate margin / difference
			this.helpCalculateTargetTotalRows(cmp, 'income');
			this.helpCalculateTargetTotalRows(cmp, 'expense');
			this.helpTitleRows(cmp);

			this.helpSetBackup(cmp, 'Excel file was uploaded');
		} catch (e) {
			alert('Upload Excel File Exception: ' + e);
		}
	}
	,

	helpShowImportReport: function (cmp, reportMessages, iconType) {
		try {
			let _this = this;
			const orgPfx = 'cb4';
			$A.createComponent(orgPfx + ":ModalContent", {'strings': reportMessages, 'iconType': iconType},
				function (content, status) {
					try {
						if (status === "SUCCESS") {
							reportMessages = content;
							cmp.find('overlayLib').showCustomModal({
								header: "Excel Import Report",
								body: reportMessages,
								showCloseButton: true,
								cssClass: "mymodal"
							});
							_hideSpinner(cmp);
						}
					} catch (e) {
						alert(e);
					}
				});
		} catch (e) {
			alert(e);
			_hideSpinner(cmp);
		}
	}
	,
/////// EXCEL ///////


	helpSetDisableTotals: function (rows) {
		rows = rows.map(function (row) {
			return row.rowValues[row.rowValues.length - 1].t = 'disabled';
		});
		return rows;
	},
	/**
	 * Makes input field disabled (All Rows)
	 */
	helpSetDisableInputs: function (rows) {
		for (let i = rows.length; i--;) for (let j = 0; j < rows[i].rowValues.length; j++) rows[i].rowValues[j].t = 'disabled';
		return rows;
	},
	/**
	 * Makes input field enabled (All Rows)
	 */
	helpSetEnableInputs: function (rows) {
		for (let i = rows.length; i--;) for (let j = 0; j < (rows[i].rowValues.length - 1); j++) rows[i].rowValues[j].t = false;
		return rows;
	},

	helpDeleteOldCalcRuleLines: function (rows) {
		let r = [];
		for (let i = 0; i < rows.length; i++) if (!(rows[i].styleClass === 'calcRule')) r.push(rows[i]);
		return r;
	},

	helpRefreshSingleApp: function (cmp) {
		_showSpinner(cmp);
		this.helpGetApp(cmp);
		this.helpGetTemplate(cmp);
		this.helpGetNeededSO(cmp);

		this.helpGetTableHeaders(cmp);
		this.helpGetTotalData(cmp);
		this.helpGetAccounts(cmp);
		this.helpGetTargetTotalData(cmp);
		this.helpGetIncomeData(cmp);
		this.helpGetDownUpSubIncomeData(cmp);
		this.helpGetTopDownSubIncomeData(cmp);
		this.helpGetExpenseData(cmp);
		this.helpGetTopDownSubExpenseData(cmp);
		this.helpGetDownUpSubExpenseData(cmp);
	}
	,
	showTable: function (cmp) {
		cmp.set("v.mode", "table");
	}
	,
	showSingle: function (cmp) {
		cmp.set("v.mode", "single");
	}
	,
	/**
	 * @param rows CBRow[]
	 */
	arrayToObjects: function (rows, cmp) {
		let splitRow = cmp.get("v.app.cb4__Decimal6__c");
		if (_isInvalid(splitRow)) splitRow = 0;
		const dis = 'disabled';

		for (let i = rows.length; i--;) {
			const inputType = rows[i].styleClass === 'calcRule' ? dis : false;
			let a = [];
			let rv = rows[i].rowValues;
			let pv = rows[i].priceValues;
			let qv = rows[i].quantityValues;
			for (let j = 0; j < rv.length; j++) a.push({
				v: rv[j],
				p: pv[j],
				q: qv[j],
				t: j < splitRow ? dis : inputType
			});

			delete rows[i].rowValues;
			delete rows[i].priceValues;
			delete rows[i].quantityValues;

			a[a.length - 1].t = dis; // last right total input is disabled
			rows[i].rowValues = a;
		}
		return rows;
	},

	/**
	 * @param rows CBRow[]
	 */
	objectsToArray: function (rows) {
		for (let i = rows.length; i--;) {
			let m = []; // money
			let q = []; // quantity / hours
			let p = []; // price / rate
			let rv = rows[i].rowValues; // {v: 750, q: 1, p: 750}

			for (let j = 0; j < rv.length; j++) {
				m.push(rv[j].v);
				q.push(rv[j].q);
				p.push(rv[j].p);
			}
			rows[i].rowValues = m;
			rows[i].quantityValues = q; // quantity / hours
			rows[i].priceValues = p; // price / rate
		}
		return rows;
	},

	/**
	 * Open Details
	 * Show table row/line details in modal window
	 * @param cmp
	 * @param key = ident/Id of selected row
	 * @param selectedRow - prepared selected row (optionally)
	 */
	helpShowDetails: function (cmp, key, selectedRow) {
		try {
			let income = cmp.get("v.incomeData");
			let grantIncome = JSON.parse(JSON.stringify(cmp.get('v.grantIncomeData')));
			let expense = cmp.get("v.expenseData");
			let grantExpense = JSON.parse(JSON.stringify(cmp.get('v.grantExpenseData')));
			for(let i = 0; i < grantIncome.length; i++){
				grantIncome[i][1].shift();
				income = income.concat(grantIncome[i][1]);
			}
			for(let i = 0; i < grantExpense.length; i++){
				grantExpense[i][1].shift();
				expense = expense.concat(grantExpense[i][1]);
			}
			// get needed row if it is not gotten
			if (_isInvalid(selectedRow)) {
				for (let i = income.length; i--;) if (income[i].key === key) selectedRow = income[i];
				for (let i = expense.length; i--;) if (expense[i].key === key) selectedRow = expense[i];
			}
			// apply properly Select Options
			if (selectedRow.ie.toLowerCase() === 'income') cmp.set("v.rowAccountSO", cmp.get("v.incomeAccountsSO")); else cmp.set("v.rowAccountSO", cmp.get("v.expenseAccountsSO"));
			cmp.set("v.row", JSON.parse(JSON.stringify(selectedRow)));

			// PRICE and QUANTITY   or  EMPLOYEE and RATE  FIRS RUN (depends on the type of the budget template)
			let template = cmp.get("v.template");
			if (template.cb4__Text2__c === "Rate and Quantity" && cmp.get("v.pricebookEntries") == null) this.helpGetPriceQuantityObject(cmp);
			if (template.cb4__Text2__c === "Employee and Rate") {
				cmp.get("v.employeeRate") == null ? this.helpGetEmployeeRateObject(cmp) : this.helpSetRate(cmp);
			}

			this.helpCalculateDialogTotals(cmp);

			// display modal dialog
			$A.util.removeClass(cmp.find("modalDiv"), "slds-hide");
			$A.util.removeClass(cmp.find("modalBackGround"), "slds-hide");
		} catch (e) {
			alert(e);
		}
	},

	helpShowGeneratorSettings: function (cmp) {
		$A.util.removeClass(cmp.find("generatorModal"), "slds-hide");
		$A.util.removeClass(cmp.find("generatorBackGround"), "slds-hide");
	},


	/**
	 * The method calculates Details modal window
	 * @param cmp
	 */
	helpCalculateDialogTotals: function (cmp) {
		try {
			let template = cmp.get("v.template");
			let row = cmp.get("v.row");
			const isComplex = template.cb4__Text2__c === "Rate and Quantity" || template.cb4__Text2__c === "Employee and Rate"; // is three lines
			if ((isComplex && !_isInvalid(row.productId) && !_isInvalid(row.pricebookId)) || (isComplex && !_isInvalid(row.rateId))) {
				for (let i = 0; i < row.rowValues.length; i++) row.rowValues[i].v = (row.rowValues[i].q * row.rowValues[i].p).toFixed(0);
			}
			this.helpSumRow(row.rowValues);
			cmp.set("v.row", row);
		} catch (e) {
			alert(e);
		}
	},

	helpSetPrice: function (cmp) {
		try {
			let row = cmp.get("v.row");
			let priceObj = cmp.get("v.pricebookEntries");
			let price = priceObj[row.productId + row.pricebookId];
			if (_isInvalid(price)) return null;

			for (let i = row.rowValues.length; i--;) row.rowValues[i].p = price;
			let pSO = cmp.get("v.productSO");
			let pbSO = cmp.get("v.pricebookSO");
			// update line description
			for (let i = pSO.length; i--;) if (pSO[i].value === row.productId) row.description = pSO[i].title;
			for (let i = pbSO.length; i--;) if (pbSO[i].value === row.pricebookId) row.description += " (" + pbSO[i].title + ")";

			cmp.set("v.row", row);

			this.helpCalculateDialogTotals(cmp);
		} catch (e) {
			alert("Help Set Price: " + e);
		}
	},

	helpSetRate: function (cmp) {
		try {
			let row = cmp.get("v.row");
			let employeeRateObj = cmp.get("v.employeeRate");
			let rateAmountObj = cmp.get("v.rateAmount");
			let employeeSO = cmp.get("v.employeeSO");
			let empRateSO = employeeRateObj[row.employeeId];
			cmp.set('v.rateSO', empRateSO === null ? [] : empRateSO);

			if (_isInvalid(row.rateId)) return null;

			let rateValue = rateAmountObj[row.rateId];

			for (let i = row.rowValues.length; i--;) row.rowValues[i].p = rateValue;
			let sep = _TEXT.APPS.TITLE_SEPARATOR;


			// update line description
			if (!_isInvalid(employeeSO)) for (let i = employeeSO.length; i--;) {
				if (employeeSO[i].value === row.employeeId) {
					row.description = employeeSO[i].title + ' ($' + rateValue + '/h)';
				}
			}

			cmp.set("v.row", row);

			this.helpCalculateDialogTotals(cmp);
		} catch (e) {
			alert("Help Set Rate: " + e);

		}
	},

	/**
	 * The method is for getting CRM Products and PriceBooks if type of the template is "Price and Quantity"
	 */
	helpGetPriceQuantityObject: function (cmp) {
		let action = cmp.get("c.getPriceQuantityObjectServer");
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				try {
					let obj = response.getReturnValue();
					cmp.set("v.pricebookSO", obj.pbSO);
					cmp.set("v.productSOFull", obj.pSO);
					cmp.set("v.productSO", obj.pSO.slice(0, 100));
					cmp.set("v.pricebookEntries", obj.prices);
				} catch (e) {
					alert(e);
				}
			} else {
				_RequestError(response, "P/Q Error", cmp);
			}
		});
		$A.enqueueAction(action);
	},

	/**
	 * The method is for getting Employees and Rates
	 */
	helpGetEmployeeRateObject: function (cmp) {
		let action = cmp.get("c.getEmployeeRateObjectServer");
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				try {
					let obj = response.getReturnValue();
					cmp.set("v.employeeSO", obj.employeeSO);
					cmp.set("v.globalRateSO", obj.globalRateSO);
					cmp.set("v.employeeRate", obj.employeeRateMap);
					cmp.set("v.rateAmount", obj.rateAmount);
					this.helpSetRate(cmp);
				} catch (e) {
					alert(e);
				}
			} else {
				_RequestError(response, "E/R Error", cmp);
			}
		});
		$A.enqueueAction(action);
	},


	helpApplyDetails: function (cmp) {
		_showSpinner(cmp);
		const allSOMap = this.helpGetAllSOMap(cmp);
		let selectedRow = cmp.get("v.row");
		for (let i = selectedRow.rowValues.length; i--;) {
			if (_isInvalidNumber(selectedRow.rowValues[i].v) || _isInvalidNumber(selectedRow.rowValues[i].p) || _isInvalidNumber(selectedRow.rowValues[i].q)) {
				_CBMessages.fireWarningMessage('Each input must have a number');
				return null;
			}
		}

		try {
			let selectedRowFound = false;
			let rows = selectedRow.ie.toLowerCase() === 'income' ? cmp.get("v.incomeData") : cmp.get("v.expenseData"); // income or expenses lines
			for (let i = rows.length; i--;) {
				if (selectedRow.key === rows[i].key) {
					selectedRowFound = true;
					selectedRow.accT = allSOMap[selectedRow.account];
					if (!_isInvalid(selectedRow.dim6)) selectedRow.dim6T = allSOMap[selectedRow.dim6]; else delete selectedRow.dim6T;
					if (!_isInvalid(selectedRow.dim7)) selectedRow.dim7T = allSOMap[selectedRow.dim7]; else delete selectedRow.dim7T;
					if (!_isInvalid(selectedRow.dim8)) selectedRow.dim8T = allSOMap[selectedRow.dim8]; else delete selectedRow.dim8T;
					if (!_isInvalid(selectedRow.dim9)) selectedRow.dim9T = allSOMap[selectedRow.dim9]; else delete selectedRow.dim9T;
					if (!_isInvalid(selectedRow.dim10)) selectedRow.dim10T = allSOMap[selectedRow.dim10]; else delete selectedRow.dim10T;
					rows[i] = selectedRow; // old row replace with a new one

					cmp.set(selectedRow.ie.toLowerCase() === 'income' ? "v.incomeData" : "v.expenseData", rows);

					this.helpCalculateTotalRows(cmp, selectedRow.ie);
					this.helpCalculateMarginRow(cmp); // calculate margin / difference
					this.helpCalculateTargetTotalRows(cmp, selectedRow.ie);

					this.helpCloseDetails(cmp);
					_hideSpinner(cmp);
					return null;
				}
			}
			if(!selectedRowFound){
				let grantSections = selectedRow.ie.toLowerCase() === 'income' ? cmp.get('v.grantIncomeData') : cmp.get('v.grantExpenseData');
				for(let key in grantSections){
					for(let j = 1; j < grantSections[key][1].length; j++){
						if(selectedRow.key === grantSections[key][1][j].key){
							selectedRowFound = true;
							selectedRow.accT = allSOMap[selectedRow.account];
							if (!_isInvalid(selectedRow.dim6)) selectedRow.dim6T = allSOMap[selectedRow.dim6]; else delete selectedRow.dim6T;
							if (!_isInvalid(selectedRow.dim7)) selectedRow.dim7T = allSOMap[selectedRow.dim7]; else delete selectedRow.dim7T;
							if (!_isInvalid(selectedRow.dim8)) selectedRow.dim8T = allSOMap[selectedRow.dim8]; else delete selectedRow.dim8T;
							if (!_isInvalid(selectedRow.dim9)) selectedRow.dim9T = allSOMap[selectedRow.dim9]; else delete selectedRow.dim9T;
							if (!_isInvalid(selectedRow.dim10)) selectedRow.dim10T = allSOMap[selectedRow.dim10]; else delete selectedRow.dim10T;
							for(let i = 0; i < grantSections[key][1][0].rowValues.length; i++){
								grantSections[key][1][0].rowValues[i].v -= parseFloat(grantSections[key][1][j].rowValues[i].v);
								grantSections[key][1][0].rowValues[i].v += parseFloat(selectedRow.rowValues[i].v);
							}
							grantSections[key][1][j] = selectedRow; // old row replace with a new one

							cmp.set(selectedRow.ie.toLowerCase() === 'income' ? "v.grantIncomeData" : "v.grantExpenseData", grantSections);

							this.helpCalculateTotalRows(cmp, selectedRow.ie);
							this.helpCalculateMarginRow(cmp); // calculate margin / difference

							this.helpCloseDetails(cmp);
							_hideSpinner(cmp);
							return null;
						}
					}
				}
			}

			// ADDING A NEW LINE
			_cl("Add new Line", "yellow");
			selectedRow.accT = allSOMap[selectedRow.account];
			if (!_isInvalid(selectedRow.dim6)) selectedRow.dim6T = allSOMap[selectedRow.dim6]; else delete selectedRow.dim6T;
			if (!_isInvalid(selectedRow.dim7)) selectedRow.dim7T = allSOMap[selectedRow.dim7]; else delete selectedRow.dim7T;
			if (!_isInvalid(selectedRow.dim8)) selectedRow.dim8T = allSOMap[selectedRow.dim8]; else delete selectedRow.dim8T;
			if (!_isInvalid(selectedRow.dim9)) selectedRow.dim9T = allSOMap[selectedRow.dim9]; else delete selectedRow.dim9T;
			if (!_isInvalid(selectedRow.dim10)) selectedRow.dim10T = allSOMap[selectedRow.dim10]; else delete selectedRow.dim10T;
			let newArray = [selectedRow];
			newArray = newArray.concat(rows);

            let grantsMap = cmp.get('v.grantsMap');
			if(selectedRow.dim8 in grantsMap){
				let grantName = grantsMap[selectedRow.dim8];
				if(selectedRow.ie.toLowerCase() === 'income'){
					let incomeGrants = cmp.get('v.grantIncomeData');
					let grantSectionFound = false;
					for(let i = 0; i < incomeGrants.length; i++){
						if(grantName === incomeGrants[i][0]){
                            for(let j = 0; j < incomeGrants[i][1][0].rowValues.length; j++){
                                incomeGrants[i][1][0].rowValues[j].v += parseFloat(selectedRow.rowValues[j].v);
                            }
                            incomeGrants[i][1].push(selectedRow);
							grantSectionFound = true;
						}
					}
					if(!grantSectionFound){
                        let newTotalRow = JSON.parse(JSON.stringify(selectedRow));
                        newTotalRow.title = 'Total';
                        newTotalRow.key = '';
						newTotalRow.styleClass = 'total';
						newTotalRow.description = 'Grant Total';
                        for(let j = 0; j < newTotalRow.rowValues.length; j++){
                            newTotalRow.rowValues[j].t = 'disabled';
                        }
                        if(_isInvalid(incomeGrants)) incomeGrants = [grantName, [newTotalRow, selectedRow]];
                        else incomeGrants.push([grantName, [newTotalRow, selectedRow]]);
					}
					cmp.set('v.grantIncomeData', incomeGrants);
				}else{
                    let expenseGrants = cmp.get('v.grantExpenseData');
                    let grantSectionFound = false;
                    for(let i = 0; i < expenseGrants.length; i++){
                        if(grantName === expenseGrants[i][0]){
                            for(let j = 0; j < expenseGrants[i][1][0].rowValues.length; j++){
                                expenseGrants[i][1][0].rowValues[j].v += parseFloat(selectedRow.rowValues[j].v);
                            }
                            expenseGrants[i][1].push(selectedRow);
                            grantSectionFound = true;
                        }
                    }
                    if(!grantSectionFound){
                        let newTotalRow = JSON.parse(JSON.stringify(selectedRow));
                        newTotalRow.title = 'Total';
                        newTotalRow.key = '';
						newTotalRow.styleClass = 'total';
						newTotalRow.description = 'Grant Total';
                        for(let j = 0; j < newTotalRow.rowValues.length; j++){
                            newTotalRow.rowValues[j].t = 'disabled';
                        }
                        if(_isInvalid(expenseGrants)) expenseGrants = [grantName, [newTotalRow, selectedRow]];
						else expenseGrants.push([grantName, [newTotalRow, selectedRow]]);
                    }
                    cmp.set('v.grantExpenseData', expenseGrants);
				}
			}else {
                cmp.set(selectedRow.ie.toLowerCase() === 'income' ? "v.incomeData" : "v.expenseData", newArray);
            }
			this.helpCalculateTotalRows(cmp, selectedRow.ie);
			this.helpCalculateMarginRow(cmp); // calculate margin / difference

			this.helpCloseDetails(cmp);
			_hideSpinner(cmp);

			this.helpSetBackup(cmp, 'Line was changed');
			// ADDING A NEW LINE
		} catch (e) {
			alert('helpApplyDetails = ' + e);
		}
	},


	helpCloseDetails: function (cmp) {
		$A.util.addClass(cmp.find("modalDiv"), "slds-hide");
		$A.util.addClass(cmp.find("generatorModal"), "slds-hide");
		$A.util.addClass(cmp.find("modalBackGround"), "slds-hide");
		$A.util.addClass(cmp.find("generatorBackGround"), "slds-hide");
		cmp.set("v.row", {});
		_hideSpinner(cmp);
	},

	helpApplyPopulation: function (cmp, process, rate) {
		try {
			_cl("PROCESS:" + process, 'pink');
			let amount = parseFloat(cmp.find('dialogSourceAmount').get("v.value"));
			if (_isInvalid(amount)) {
				alert('Please input some base amount');
				return null;
			}
			let row = cmp.get("v.row");
			let values = row.rowValues;
			const number = values.length - 1; // lenght of line
			let total = 0;

			switch (process) {
				case 'spread':
					for (let i = 0; i < number; i++) values[i].v = amount;
					values[number].v = amount * number;
					break;
				case 'splitBY':
					const part = (amount / number).toFixed(0);
					for (let i = 0; i < number; i++) values[i].v = part;
					const rest = amount - part * number;
					values[number - 1].v = values[number - 1].v - 0 + rest;
					values[number].v = amount;
					break;
				case 'multiply':
					for (let i = 0; i < number; i++) {
						values[i].v *= amount;
						total += values[i].v;
					}
					values[number].v = total;
					break;
				case 'divide':
					if (amount === 0.0) {
						alert('Cannot be divided by zero');
						return null;
					}
					for (let i = 0; i < number; i++) {
						values[i].v = Math.floor(values[i].v / amount);
						total += values[i].v;
					}
					values[number].v = total;
					break;
				case 'increase':
					for (let i = 0; i < number; i++) {
						values[i].v = parseFloat(values[i].v) + amount;
						total += values[i].v - 0;
					}
					values[number].v = total;
					break;
				case 'back':
					let income = cmp.get("v.incomeData");
					let expense = cmp.get("v.expenseData");
					let tableRow;
					for (let i = income.length; i--;) if (income[i].key === row.key) tableRow = income[i];
					for (let i = expense.length; i--;) if (expense[i].key === row.key) tableRow = expense[i];
					if (_isInvalid(tableRow)) {
						for (let i = 0; i < number; i++) values[i].v = 0;
					} else {
						for (let i = 0; i < number; i++) values[i].v = tableRow.rowValues[i].v;
					}
					break;
				default:
					_cl('Unknown process', 'red')
			}

			cmp.set("v.row", row);
		} catch (e) {
			alert(e);
		}
	},

	/**
	 * Hide line details
	 */
	helpShrinkDetails: function (cmp, rowShrinkId) {
		let rowExpandId = rowShrinkId.replace('shrink', 'expand');
		$("#" + rowExpandId).hide();
		$("#" + rowShrinkId).show();
	}
	,

	/**
	 * Method hides all expand sections
	 */
	shrinkAllAccounts: function () {
		$("[id$='expand']").hide();
		$("[id$='shrink']").show();
	}
	,

	helpRefreshChat: function (cmp) {
		let chat = cmp.find("chat");
		chat.refresh();
	}
	,
	helpShowExcelPanel: function (cmp) {
		let exPanel = $(cmp.find("excelPanel").getElement());
		if (exPanel.css('right') === '-350px') {
			exPanel.animate({right: '0', opacity: 1});
		} else {
			exPanel.animate({right: '-350px', opacity: 0.9});
		}
	}
	,
	helpShowPDFPanel: function () {
		let PDFPanel = $("#PDFPanel");
		if (PDFPanel.css('right') === '-350px') {
			PDFPanel.animate({right: '0', opacity: 1});
		} else {
			PDFPanel.animate({right: '-350px', opacity: 0.9});
		}
	}
	,
	isTopDown: function (cmp) {
		return cmp.get("v.template.cb4__Text1__c") === 'Top-Down';
	}
	,
	showIncomePart: function (cmp) {
		return cmp.get('v.template.cb4__Boolean2__c');
	}
	,
	showExpensePart: function (cmp) {
		return cmp.get('v.template.cb4__Boolean3__c');
	}
	,
	disableButtonSave: function (cmp) {
		cmp.set('v.saveButtonDisabled', true);
	}
	,
	/**
	 * Save button is enable only after the page has loaded in full extent
	 */
	enableButtonSave: function (cmp) {
		let filterIsNotEmpty = Object.keys(cmp.get("v.pageFilter")).length !== 0;
		if (cmp.get('v.app.cb4__Status__c') === 'Posted' || filterIsNotEmpty) return;
		cmp.set('v.saveButtonDisabled', false);
	},

	helpFilterProducts: function (cmp, filter) {
		cmp.set('v.productIsSearching', true);
		window.setTimeout(
			$A.getCallback(function () {
				try {
					//let filteredOptions = [];
					const allOptions = cmp.get("v.productSOFull");
					if (_isInvalid(filter) || filter.length === 0) {
						cmp.set("v.productSO", allOptions.slice(0, 100));
						cmp.set('v.productIsSearching', false);
						return 1;
					}
					//for (let i = 0; i < allOptions.length; i++) if (allOptions[i].title.indexOf(filter) !== -1) filteredOptions.push(allOptions[i]);
					let filteredOptions = allOptions.filter(item => item.title.indexOf(filter) !== -1);
					cmp.set("v.productSO", filteredOptions);
					cmp.set('v.productIsSearching', false);
				} catch (e) {
					alert(e);
				}
			}, 10));
	},

	helpSetTableHeight: function (cmp) {
		$(cmp.find("budgetsTable").getElement()).height(window.innerHeight - 333);
		let ls = window.localStorage;
		let storedResolution = ls.getItem('resolutionValues');
		storedResolution = storedResolution !== undefined ? JSON.parse(storedResolution) : undefined;
		let curRes = {h:window.innerHeight,w:window.innerWidth};
		if(curRes.w < 1366 || curRes.h < 768)
		{
			let noteResStatus = ls.getItem('resolutionNotify');
			noteResStatus = noteResStatus === null ? 'true' : noteResStatus;
			if(noteResStatus === 'true' || (storedResolution !== undefined && storedResolution.w !== curRes.w || storedResolution.h !== curRes.h)){
				$A.util.removeClass(cmp.find("cbnotification"), "slds-hide");
			}
		}
		ls.setItem('resolutionValues', JSON.stringify(curRes));
	},

	/////// ADDITIONAL APP COMPONENT ///////
	helpGetAdditionalAppComponent: function (cmp) {
		_showSpinner(cmp);

		window.setTimeout(
			$A.getCallback(function () {

				try {
					let additionalComponentName = cmp.get("v.appDimension.cb4__TagFunctionalCmpName__c"); // set in the helpGetDimension method
					if (_isInvalid(additionalComponentName)) {
						_cl("Additional App Component is not provided for this Budget App", 'blue');
						_hideSpinner(cmp);
						return null;
					} else {
						_cl("The Additional Component Name is " + additionalComponentName, 'blue');
					}

					cmp.set("v.additionalComponent", []);// erase old component if it exists
					$A.createComponent(additionalComponentName.includes(':') ? additionalComponentName : 'cb4:' + additionalComponentName,
						{
							"app": cmp.get("v.app"),
							"template": cmp.get("v.template"),
							"incomeData": cmp.get("v.incomeData"),
							"incomeDownUpSubData": cmp.get("v.incomeDownUpSubData"),
							"incomeTopDownSubData": cmp.get("v.incomeTopDownSubData"),
							"expenseData": cmp.get("v.expenseData"),
							"expenseDownUpSubData": cmp.get("v.expenseDownUpSubData"),
							"expenseTopDownSubData": cmp.get("v.expenseTopDownSubData"),
							"totalData": cmp.get('v.totalData'),
							"targetTotalData": cmp.get('v.targetTotalData'),
							"apply": cmp.getReference("c.applyAdditionalComponent")
						},
						function (additionalCMP, status, errorMessage) {
							cmp.set("v.additionalCMP", additionalCMP);
							if (status === "SUCCESS") {
								let newCmp = cmp.get("v.additionalComponent");
								newCmp.push(additionalCMP);
								cmp.set("v.additionalComponent", newCmp);
							} else if (status === "INCOMPLETE") {
							} else if (status === "ERROR") {
								_CBMessages.fireErrorMessage("Additional Component failed to load " + errorMessage);
							}
							_hideSpinner(cmp);
						}
					);
				} catch (e) {
					alert(e);
				}
			}, 10));
	},
	/////// ADDITIONAL APP COMPONENT ///////
	/////// ADDITIONAL BUDGET LINE COMPONENT ///////
	helpGetAdditionalBudgetLineComponent: function (cmp) {
		_showSpinner(cmp);

		window.setTimeout(
			$A.getCallback(function () {

				try {
					let additionalComponentName = cmp.get("v.amountDimension.cb4__TagFunctionalCmpName__c"); // set in the helpGetDimension method
					if (_isInvalid(additionalComponentName)) {
						_cl("Additional Budget Line Component is not provided for this Budget App", 'blue');
						_hideSpinner(cmp);
						return null;
					} else {
						_cl("The Additional Budget Line Component Name is " + additionalComponentName, 'blue');
					}

					cmp.set("v.additionalBudgetLineComponent", []);// erase old component if it exists
					$A.createComponent(additionalComponentName.includes(':') ? additionalComponentName : 'cb4:' + additionalComponentName,
						{
							"app": cmp.get('v.app'),
							"template": cmp.get("v.template"),
							"row": cmp.get("v.row"),
							"editDisabled" : cmp.get('v.editDisabled'),
							"apply": cmp.getReference("c.applyAdditionalComponent")
						},
						function (additionalCMP, status, errorMessage) {
							cmp.set("v.additionalBLCMP", additionalCMP);
							if (status === "SUCCESS") {
								let newCmp = cmp.get("v.additionalBudgetLineComponent");
								newCmp.push(additionalCMP);
								cmp.set("v.additionalBudgetLineComponent", newCmp);
							} else if (status === "INCOMPLETE") {
							} else if (status === "ERROR") {
								_CBMessages.fireErrorMessage("Additional Budget Line Component failed to load " + errorMessage);
							}
							_hideSpinner(cmp);
						}
					);
				} catch (e) {
					alert(e);
				}
			}, 10));
	},
	/////// ADDITIONAL BUDGET LINE COMPONENT ///////
	helpFoldUnfoldList: function (cmp) {
		let lvl = cmp.get('v.hideLevel') - 0;
		let budgetLineData = cmp.get("v.gridData");
		let newUnfoldList = [];
		function unFold(item, depth){
			if(lvl !== 1 && depth < lvl){
				depth++;
				newUnfoldList.push(item.Id)
				if(item._children !== undefined) item._children.forEach(child => unFold(child, depth));
			}
			if(lvl === 1){
				newUnfoldList.push(item.Id);
				if(item._children !== undefined) item._children.forEach(child => unFold(child, depth));
			}
		}
		budgetLineData.forEach(function (budget) {
			unFold(budget, 1);
		});
		cmp.set("v.gridExpandedRows", newUnfoldList);
		_hideSpinner(cmp);
	},

	getAttachedDocuments: function (cmp) {
		let recordId = cmp.get("v.app.Id");
		function setAttach(cmp, response){
			const filesArr = response.getReturnValue();
			let files = [];
			filesArr.forEach(function (value) {
				const params = value.split(',');
				let resObj = {};
				resObj.Title = params[1];
				resObj.Id = params[0];
				resObj.url = '/' + params[0];
				files.push(resObj);
			});
			cmp.set('v.attachments', files);
		}
		_CBRequest(
			cmp,
			"c.getDocumentsByRecordIdServer",
			{
				"recordId":recordId
			},
			null,
			setAttach,
			null,
			'getAttachedDocuments error'
		);
	},

	helpGetGrantsList: function(cmp) {
		_CBRequest(
			cmp,
			"c.getGrantsListServer",
			null,
			'v.grantsMap',
			null,
			null,
			'Failed to get Grants List'
		);
	}
});