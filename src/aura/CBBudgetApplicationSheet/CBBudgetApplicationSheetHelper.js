/**
 * Created by Alex JR on 21/08/19.
 */
({

	helpRefreshData: function (cmp) {
		try {
			this.helpGetAllAppsFilteredByContext(cmp);
			this.helpGetDimsNames(cmp);
			this.helpGetMainAppSO(cmp);

			let incomeRows = JSON.parse(JSON.stringify(cmp.get("v.incomeDataOriginal")));
			let expenseRows = JSON.parse(JSON.stringify(cmp.get("v.expenseDataOriginal")));
			_cl('expenseRows ' + JSON.stringify(expenseRows));
			let selectedGroup = cmp.get("v.selectedGroup");
			let groupByApps = cmp.get("v.groupByApps");
			if (groupByApps) cmp.set("v.showDetails", true);
			cmp.set("v.showDetailsDisabled", groupByApps);
			let showDetails = cmp.get("v.showDetails");

			// calculate global totals
			this.helpGetTotalData(cmp, incomeRows, expenseRows);

			// PRODUCT MODE
			if (selectedGroup === 'product') {
				this.generateProductStructure(cmp, incomeRows, expenseRows);
				cmp.set("v.incomeData", []);
				cmp.set("v.expenseData", []);

				return 0;
			} else {
				cmp.set("v.productData", []);
			}
			// PRODUCT MODE

			// EMPLOYEE MODE
			if (selectedGroup === 'employee') {
				this.generateEmployeeStructure(cmp, incomeRows, expenseRows);
				cmp.set("v.incomeData", []);
				cmp.set("v.expenseData", []);

				return 0;
			} else {
				cmp.set("v.employeeData", []);
			}
			// EMPLOYEE MODE


			// grouping by Apps
			if (groupByApps) {
				_cl('groupByApps ' + groupByApps, 'red');
				incomeRows = this.splitRowsByApps(incomeRows);
				expenseRows = this.splitRowsByApps(expenseRows);
			}

			// grouping by filter
			_cl('selectedGroup=' + selectedGroup, 'lemon');
			_cl('showDetails=' + showDetails, 'lemon');
			if (!_isInvalid(selectedGroup)) {
				incomeRows = this.splitRowsByFilter(incomeRows, selectedGroup, showDetails);
				expenseRows = this.splitRowsByFilter(expenseRows, selectedGroup, showDetails);
				_cl('expenseRows splitRowsByFilter ' + JSON.stringify(expenseRows));
			}

			incomeRows.forEach(function (item) {
				_cl(JSON.stringify(item), 'green');
			});

			expenseRows.forEach(function (item) {
				_cl(JSON.stringify(item), 'green');
			});


			cmp.set("v.incomeData", incomeRows);
			cmp.set("v.expenseData", expenseRows);



		} catch (e) {
			alert('Refresh Data Error: ' + e);
		}
	},
	helpGetAllApps: function (cmp) {
		try {
			let action = cmp.get("c.getAllChildrenIdsServer");
			action.setParams({
				"appId": cmp.get("v.recordId")
			});
			action.setCallback(this, function (response) {
				_cl('helpGetAllApps callback', 'cyan');
				let state = response.getState();
				if (state === "SUCCESS") {
					let apps = response.getReturnValue();
					cmp.set("v.apps", apps);

					let childrenId = []; // list af all subsidiary apps
					let allApps = cmp.get("v.apps");
					let appId = cmp.get("v.recordId");
					for (let i = 0; i < allApps.length; i++) {
						if (allApps[i].Id === appId) {
							let currApp = allApps[i];
							cmp.set("v.app", currApp);
							cmp.set("v.headerTitle", currApp.Name);
							document.title = currApp.Name + ' Summary';
						}
						childrenId.push(allApps[i].Id);
					}
					this.helpGetSectionData(cmp, childrenId, 'income');
					this.helpGetSectionData(cmp, childrenId, 'expense');
				} else {
					_RequestError(response, _TEXT.APP_SHEET.FAILED_GET_ALL_APPS, cmp);
				}
			});
			$A.enqueueAction(action);
		} catch (e) {
			alert("helpGetAllApps:" + e);
		}
	},
	helpGetRootApp: function (cmp) {
		let action = cmp.get("c.getBudgetAppsServer");
		action.setParams({
			"appId": cmp.get("v.recordId")
		});
		action.setCallback(this, function (response) {
			_cl('helpGetRootApp callback', 'cyan');
			let state = response.getState();
			if (state === "SUCCESS") {
				let apps = response.getReturnValue();
				cmp.set("v.rootApp", apps[0]);
				const selectedGroup = _isInvalid(apps[0].cb4__Tag2__r.cb4__Text4__c) ? 'dim8Name' : apps[0].cb4__Tag2__r.cb4__Text4__c;
				cmp.set("v.selectedGroup", selectedGroup);
				document.title = apps[0].cb4__TagLabel__c + ' Summary';
			} else {
				_RequestError(response, _TEXT.APPS.FAILED_GET_APP, cmp);
			}
		});
		$A.enqueueAction(action);
	},

	helpGetAllAppsFilteredByContext: function (cmp) {
		let action = cmp.get("c.getBudgetAppsServer");
		action.setCallback(this, function (response) {
			_cl('helpGetAllAppsFilteredByContext callback', 'cyan');
			let state = response.getState();
			if (state === "SUCCESS") {
				let apps = response.getReturnValue();
				let incomeRows = cmp.get("v.incomeRowsOfApps");
				let expenseRows = cmp.get("v.expenseRowsOfApps");

				_cl('apps size == ' + apps.length);
				_cl('income size == ' + incomeRows.length);
				_cl('expense size == ' + expenseRows.length);

				let longNamesCount = 1;
				apps.forEach(function (currApp) { // put to the Apps it's own lines without children's lines
					let appName = ("📈 " + currApp.cb4__TagLabel__c).replace(":", "\uA789");
					appName = appName.replace("'", "\u00B4");
					appName = (appName.length > 30) ? ((appName.substring(0, 27)) + " " + longNamesCount++) : appName;
					currApp.cb4__TagLabel__c = appName;

					for (let k = 0; k < incomeRows.length; k++) {
						let currLine = incomeRows[k];
						if (currApp.incomeLines === undefined && currLine.app === currApp.Id) currApp.incomeLines = [];
						if (currLine.app === currApp.Id) currApp.incomeLines.push(currLine);
					}

					for (let k = 0; k < expenseRows.length; k++) {
						let currLine = expenseRows[k];
						if (currApp.expenseLines === undefined && currLine.app === currApp.Id) currApp.expenseLines = [];
						if (currLine.app === currApp.Id) currApp.expenseLines.push(currLine);
					}

				});

				apps.forEach(function (currApp) {
					currApp.hasIncome = false;
					currApp.hasExpense = false;
					if (!_isInvalid(currApp.incomeLines)) currApp.hasIncome = true;
					if (!_isInvalid(currApp.incomeLines)) currApp.hasExpense = true;

					for (let j = 0; j < apps.length; j++) {
						let currChildApp = apps[j];
						if (currApp.children === undefined && currChildApp.cb4__Tag1__c === currApp.Id) currApp.children = [];
						if (currChildApp.cb4__Tag1__c === currApp.Id) currApp.children.push(currChildApp);
					}

				});
				cmp.set("v.allApps", apps);
				this.appsStructure(cmp);
			} else {
				_RequestError(response, _TEXT.APPS.FAILED_GET_APP, cmp);
			}
		});
		$A.enqueueAction(action);
	},

	helpGetTableHeaders: function (cmp) {
		try {
			let action = cmp.get("c.getTableHeadersServer");
			action.setParams({
				"appId": cmp.get("v.recordId")
			});
			action.setCallback(this, function (response) {
				_cl('helpGetTableHeaders callback', 'cyan');
				let state = response.getState();
				if (state === "SUCCESS") {
					let headers = response.getReturnValue();
					cmp.set("v.headers", headers);
				} else {
					_RequestError(response, _TEXT.APP_SHEET.FAILED_GET_HEADERS, cmp);
				}
			});
			$A.enqueueAction(action);
		} catch (e) {
			alert("helpGetTableHeaders:" + e);
		}
	},
	helpGetAllAccountsAndDimension: function (cmp) {
		try {
			let action = cmp.get("c.getAllAccountsAndDimensionsServer");
			action.setCallback(this, function (response) {
				_cl('helpGetAllAccountsAndDimension callback', 'cyan');
				let state = response.getState();
				if (state === "SUCCESS") {
					let all = response.getReturnValue();
					cmp.set("v.allAccAndDims", all);
				} else {
					_RequestError(response, _TEXT.APP_SHEET.FAILED_GET_ALL_ACC_AND_DIMS, cmp);
				}
			});
			$A.enqueueAction(action);
		} catch (e) {
			alert("helpGetAllAccountsAndDimension:" + e);
		}
	},
	/**
	 * The method gets a list of grouping items like Account, Product, etc.
	 * @param cmp
	 */
	helpGetGroupFilterSO: function (cmp) {
		function callback() {
			_cl('callback helpGetGroupFilterSO', 'cyan');
		}
		_CBRequest(cmp, "c.getFilterCategoriesSOServer", null, "v.groupFilter", callback, null, 'ERROR', false);
	},
	/**
	 * The method gets data from the server for the income section, then for the expense data
	 * @param cmp
	 * @param childrenId
	 * @param type  income or expense
	 * INIT TWICE
	 */
	helpGetSectionData: function (cmp, childrenId, type) {
		try {
			const arrayAttrOriginal = "v." + type + "DataOriginal";
			let action = cmp.get("c.getRowsServer");
			action.setParams({
				"appId": cmp.get("v.recordId"),
				"childrenId": childrenId,
				"type": type
			});
			action.setCallback(this, function (response) {
				_cl('helpGetSectionData callback' ,'cyan');
				let state = response.getState();
				if (state === "SUCCESS") {
					let rows = response.getReturnValue();
					rows = this.arrayToObjects(rows, "v", cmp.get("v.allAccAndDims"));
					_cl(JSON.stringify(rows[0]), 'white');

					if (rows.length > 0) {
						cmp.set(arrayAttrOriginal, rows);
					} else {
						cmp.set(arrayAttrOriginal, []);
					}

					//final preparation
					if (type === 'expense') {
						this.helpRefreshData(cmp);
						cmp.set("v.expenseRowsOfApps", rows);
					} else {
						cmp.set("v.incomeRowsOfApps", rows);
					}
				} else {
					_RequestError(response, "Failed to load " + type + " data", cmp);
				}
			});
			$A.enqueueAction(action);
		} catch (e) {
			alert("Failed to load " + type + " data : " + e);
		}
	},

	getFieldsToDelete: function () {
		return ['key', 'dim6Name', 'dim7Name', 'dim8Name', 'dim9Name', 'dim10Name', 'status', 'accName'];
	},
	/**
	 * Method for splitting list
	 * @param rows (income or expense lines)
	 */
	splitRowsByApps: function (rows) {
		if (rows.length === 0) return [];
		let appMap = {};
		let row, newRows, lines, appHeader;
		newRows = [];
		const fieldsToDelete = this.getFieldsToDelete();

		try {

			for (let i = rows.length; i--;) {
				row = rows[i]; // current row
				lines = appMap[row.app]; // list of rows of the same app
				if (lines === undefined) { // the first meeting
					appMap[row.app] = [row];
				} else {
					lines.push(row);
				}
			}

			Object.keys(appMap).forEach(function (key) {
				lines = appMap[key];

				appHeader = JSON.parse(JSON.stringify(lines[0]));
				for (let i = 0; i < fieldsToDelete.length; i++) delete appHeader[fieldsToDelete[i]];
				for (let i = appHeader.rowValues.length; i--;) appHeader.rowValues[i].v = 0;
				delete appHeader.title;

				appHeader.appName = '📈 ' + appHeader.appName;
				appHeader.type = 'subTotal';

				for (let i = lines.length; i--;) {
					delete lines[i].appName;
					for (let j = 0; j < lines[i].rowValues.length; j++) {
						appHeader.rowValues[j].v += lines[i].rowValues[j].v - 0;
					}
				}

				lines.unshift(appHeader);
				newRows = newRows.concat(lines);
			});
		} catch (e) {
			alert('splitRowsByApps: line:' + e.lineNumber + ' - ' + e);
			_cl('splitRowsByApps: ' + e, 'red');
			return rows;
		}

		return newRows;
	},
	splitRowsByFilter: function (rows, selectedGroup, showDetails) {
		if (rows.length === 0) return rows;

		let subgroups = []; // list of lists
		let newRows = []; // result
		let list, row, groupObj, subFilterRows, rowMark, groupFilterHeader;
		list = [];
		const fieldsToDelete = this.getFieldsToDelete();

		try {
			for (let i = 0; i < rows.length; i++) {
				row = rows[i];
				if (list.length !== 0 && row.type !== undefined) { // not the first app subtotal line detected
					subgroups.push(JSON.parse(JSON.stringify(list)));
					list = [row];
					_cl('list ' + JSON.stringify(list));
				} else {
					list.push(row);
				}
			}
			subgroups.push(JSON.parse(JSON.stringify(list)));
			for (let i = 0; i < subgroups.length; i++) { // iterate over one application
				let oneAppLines = subgroups[i];
				const appTotalLine = oneAppLines[0].type !== undefined ? oneAppLines[0] : null;

				let newOneAppLines = [];
				if (appTotalLine != null) newOneAppLines.push(appTotalLine);

				groupObj = {};
				for (let j = 0; j < oneAppLines.length; j++) {
					row = oneAppLines[j];
					if (row.type !== undefined) continue; // App total line
					rowMark = row[selectedGroup];
					if (_isInvalid(rowMark)) rowMark = 'general';
					subFilterRows = groupObj[rowMark];
					if (subFilterRows === undefined) { // first met
						subFilterRows = [];
						groupObj[rowMark] = subFilterRows;
					}
					subFilterRows.push(row);
				}

				Object.keys(groupObj).forEach(function (k) {
					subFilterRows = groupObj[k];
					_cl(' subFilterRows = groupObj[k] ' + JSON.stringify(subFilterRows), 'green');
					groupFilterHeader = JSON.parse(JSON.stringify(subFilterRows[0]));
					for (let i = groupFilterHeader.rowValues.length; i--;) groupFilterHeader.rowValues[i].v = 0;
					_cl(' groupFilterHeader ' + JSON.stringify(groupFilterHeader), 'green');
					groupFilterHeader.type = 'groupTotal';
					for (let i = 0; i < fieldsToDelete.length; i++) delete groupFilterHeader[fieldsToDelete[i]];
					delete groupFilterHeader.appName;
					groupFilterHeader.title = k;

					for (let i = subFilterRows.length; i--;) {
						for (let j = 0; j < subFilterRows[i].rowValues.length; j++) {
							groupFilterHeader.rowValues[j].v += subFilterRows[i].rowValues[j].v - 0;
						}
					}
					_cl('subFilterRows ' + JSON.stringify(subFilterRows), 'green');
					_cl('groupFilterHeader ' + JSON.stringify(groupFilterHeader), 'red');
					subFilterRows.unshift(groupFilterHeader);
					_cl('subFilterRows ' + JSON.stringify(subFilterRows), 'green');
					newOneAppLines = newOneAppLines.concat(subFilterRows);
					_cl('newOneAppLines ' + JSON.stringify(newOneAppLines), 'green');
				});
				_cl('newRows ' + JSON.stringify(newRows), 'white');
				newRows = newRows.concat(newOneAppLines);
			}
		} catch (e) {
			alert("splitRowsByFilter = " + e);
		}

		if (!showDetails) {
			newRows = newRows.filter(function (row) {
				return row.type === 'groupTotal';
			});
		}
		_cl('newRows ' + JSON.stringify(newRows), 'red');
		return newRows;
	},

	///// PRODUCT  MODE

	generateProductStructure: function (cmp, incomeRows, expenseRows) {
		try {
			let i, j, p, k, rows, row;
			let BAObj = {};
			let result = [];
			const groupByApps = cmp.get("v.groupByApps");

			if (groupByApps) {
				for (i = 0; i < incomeRows.length; i++) {
					rows = BAObj[incomeRows[i].app];
					if (rows === undefined) rows = [];
					rows.push(incomeRows[i]);
					BAObj[incomeRows[i].app] = rows;
				}
				for (i = 0; i < expenseRows.length; i++) {
					rows = BAObj[expenseRows[i].app];
					if (rows === undefined) rows = [];
					rows.push(expenseRows[i]);
					BAObj[expenseRows[i].app] = rows;
				}
				const APPIds = Object.keys(BAObj);
				for (j = APPIds.length; j--;) {
					const appId = APPIds[j];
					let appHeader = JSON.parse(JSON.stringify(BAObj[appId][0]));
					delete appHeader.quantityValues;
					delete appHeader.priceValues;
					delete appHeader.accName;
					appHeader.appName += ' (App Margin)';
					delete appHeader.title;
					appHeader.type = 'subTotal';
					for (p = appHeader.rowValues.length; p--;) appHeader.rowValues[p].v = 0;

					let ir = [];
					let er = [];
					for (let l = 0; l < BAObj[appId].length; l++) {
						row = BAObj[appId][l];
						if (row.ie === 'income') {
							ir.push(row);
							for (p = appHeader.rowValues.length; p--;) appHeader.rowValues[p].v = appHeader.rowValues[p].v - 0 + row.rowValues[p].v - 0;
						} else {
							er.push(row);
							for (p = appHeader.rowValues.length; p--;) appHeader.rowValues[p].v = appHeader.rowValues[p].v - row.rowValues[p].v;
						}
					}
					let blocks = this.generateProductGroups(cmp, ir, er);
					blocks[0].rows.unshift(appHeader);
					result = result.concat(blocks);
				}
			} else {
				result = this.generateProductGroups(cmp, incomeRows, expenseRows);
			}
			cmp.set("v.productData", result);
		} catch (e) {
			alert(e);
		}
	},

	generateProductGroups: function (cmp, incomeRows, expenseRows) {

		try {
			let i, j, p, k, rows;
			for (i = 0; i < incomeRows.length; i++) {
				_cl("->" + JSON.stringify(incomeRows[i]), "lime");
			}
			for (i = 0; i < expenseRows.length; i++) {
				_cl("->" + JSON.stringify(expenseRows[i]), "orange");
			}

			let blocks = [];
			const priceQuantityObject = cmp.get("v.priceQuantityObject");
			let pSOMap = {};
			for (i = priceQuantityObject.pSO.length; i--;) pSOMap[priceQuantityObject.pSO[i].value] = priceQuantityObject.pSO[i].title;

			let productMap = {};
			for (i = 0; i < incomeRows.length; i++) productMap[incomeRows[i].productId] = true;
			for (i = 0; i < expenseRows.length; i++) productMap[expenseRows[i].productId] = true;
			const productIds = Object.keys(productMap);
			for (p = productIds.length; p--;) {
				const prId = productIds[p];
				let block = {};
				block.header = prId === "undefined" ? 'Other' : pSOMap[prId];

				rows = [];

				for (i = 0; i < incomeRows.length; i++) if (incomeRows[i].productId === prId || (incomeRows[i].productId === undefined && prId === "undefined")) rows.push(incomeRows[i]);
				for (i = 0; i < expenseRows.length; i++) if (expenseRows[i].productId === prId || (expenseRows[i].productId === undefined && prId === "undefined")) rows.push(expenseRows[i]);
				let marginRow = JSON.parse(JSON.stringify(rows[0]));
				for (i = marginRow.rowValues.length; i--;) marginRow.rowValues[i].v = 0;

				block.unitName = '';
				try {
					let regEx = new RegExp("\\((.+?)\\)", "g");
					let unitArr = regEx.exec(block.header);
					if (unitArr !== null) {
						block.unitName = unitArr[1];
					}
				} catch (e) {
					_cl('unit regexp error: ' + e, 'red');
				}


				marginRow.appName = block.header + ' (Product Margin)';
				marginRow.app = prId;
				marginRow.type = 'groupTotal';
				delete marginRow.accName;
				delete marginRow.title;
				delete marginRow.priceValues;
				delete marginRow.quantityValues;
				delete marginRow.dim6Name;
				delete marginRow.dim7Name;
				delete marginRow.dim8Name;
				delete marginRow.dim9Name;
				delete marginRow.dim10Name;

				try {
					for (i = rows.length; i--;) {
						if (rows[i].ie === 'income') {
							for (j = 0; j < rows[i].rowValues.length; j++) marginRow.rowValues[j].v = rows[i].rowValues[j].v - 0 + marginRow.rowValues[j].v;
						} else {
							for (j = 0; j < rows[i].rowValues.length; j++) marginRow.rowValues[j].v = marginRow.rowValues[j].v - rows[i].rowValues[j].v;
						}
						delete rows[i].appName;

						let totalQ = 0;

						if (rows[i].quantityValues !== undefined && rows[i].quantityValues !== null) {
							for (k = rows[i].quantityValues.length; k--;) totalQ = totalQ + rows[i].quantityValues[k] - 0;
							rows[i].quantityValues.push(totalQ)
						}
						if (totalQ === 0) {
							delete rows[i].quantityValues;
							delete rows[i].priceValues;
						}
					}
				} catch (er) {
					alert("ROW SCOPE:" + er);
				}

				rows.unshift(marginRow);
				block.rows = rows;
				blocks.push(block);
			}

			return blocks;

		} catch (e) {
			alert(e);
		}
	},

	///// PRODUCT  MODE

	///// EMPLOYEE  MODE

	generateEmployeeStructure: function (cmp, incomeRows, expenseRows) {
		try {
			let i, j, p, k, rows, row;
			let BAObj = {};
			let result = [];
			const groupByApps = cmp.get("v.groupByApps");

			if (groupByApps) {
				for (i = 0; i < incomeRows.length; i++) {
					rows = BAObj[incomeRows[i].app];
					if (rows === undefined) rows = [];
					rows.push(incomeRows[i]);
					BAObj[incomeRows[i].app] = rows;
				}
				for (i = 0; i < expenseRows.length; i++) {
					rows = BAObj[expenseRows[i].app];
					if (rows === undefined) rows = [];
					rows.push(expenseRows[i]);
					BAObj[expenseRows[i].app] = rows;
				}
				const APPIds = Object.keys(BAObj);
				for (j = APPIds.length; j--;) {
					const appId = APPIds[j];
					let appHeader = JSON.parse(JSON.stringify(BAObj[appId][0]));

					['accName', 'title', 'status', 'title', 'key', 'unitName', 'priceValues', 'quantityValues',
						'dim6', 'dim7', 'dim8', 'dim9', 'dim10',
						'dim6Name', 'dim7Name', 'dim8Name', 'dim9Name', 'dim10Name'].forEach(e => delete appHeader[e]);

					appHeader.type = 'subTotal';
					for (p = appHeader.rowValues.length; p--;) appHeader.rowValues[p].v = 0;

					let ir = [];
					let er = [];
					for (let l = 0; l < BAObj[appId].length; l++) {
						row = BAObj[appId][l];
						if (row.ie === 'expense') {
							er.push(row);
							for (p = appHeader.rowValues.length; p--;) appHeader.rowValues[p].v = appHeader.rowValues[p].v + 0 + row.rowValues[p].v;
						}
					}
					let blocks = this.generateEmployeeGroups(cmp, ir, er);
					blocks[0].rows.unshift(appHeader);
					result = result.concat(blocks);
				}
			} else {
				result = this.generateEmployeeGroups(cmp, incomeRows, expenseRows);
			}
			cmp.set("v.employeeData", result);
		} catch (e) {
			alert(e);
		}
	},

	generateEmployeeGroups: function (cmp, incomeRows, expenseRows) {
		try {
			let i, j, p, k, rows, block;
			_cl("Emp mode", "red");

			let blocks = [];
			const employeeRateObject = cmp.get("v.employeeRateObject");
			let empSOMap = {};
			for (i = employeeRateObject.employeeSO.length; i--;) empSOMap[employeeRateObject.employeeSO[i].value] = employeeRateObject.employeeSO[i].title;

			let employeeMap = {};
			for (i = 0; i < incomeRows.length; i++) employeeMap[incomeRows[i].employeeId] = true;
			for (i = 0; i < expenseRows.length; i++) employeeMap[expenseRows[i].employeeId] = true;

			const employeeIds = Object.keys(employeeMap);
			for (p = employeeIds.length; p--;) {
				const empId = employeeIds[p];

				block = {};
				block.header = empId === "undefined" ? 'Other' : empSOMap[empId];

				rows = [];

				for (i = 0; i < incomeRows.length; i++) if (incomeRows[i].employeeId === empId || (incomeRows[i].employeeId === undefined && empId === "undefined")) rows.push(incomeRows[i]);
				for (i = 0; i < expenseRows.length; i++) if (expenseRows[i].employeeId === empId || (expenseRows[i].employeeId === undefined && empId === "undefined")) rows.push(expenseRows[i]);
				let marginRow = JSON.parse(JSON.stringify(rows[0]));
				for (i = marginRow.rowValues.length; i--;) marginRow.rowValues[i].v = 0;

				block.unitName = '';
				try {
					let regEx = new RegExp("\\((.+?)\\)", "g");
					let unitArr = regEx.exec(block.header);
					if (unitArr !== null) {
						block.unitName = unitArr[1];
					}
				} catch (e) {
					_cl('unit regexp error: ' + e, 'red');
				}

				marginRow.appName = block.header;
				marginRow.app = empId;
				marginRow.type = 'groupTotal';

				['accName', 'title', 'status', 'key', 'unitName', 'priceValues', 'quantityValues',
					'dim6', 'dim7', 'dim8', 'dim9', 'dim10',
					'dim6Name', 'dim7Name', 'dim8Name', 'dim9Name', 'dim10Name'].forEach(e => delete marginRow[e]);

				try {
					for (i = rows.length; i--;) {

						for (j = 0; j < rows[i].rowValues.length; j++) marginRow.rowValues[j].v = marginRow.rowValues[j].v + 0 + rows[i].rowValues[j].v;
						delete rows[i].appName;
						let totalQ = 0;

						if (rows[i].quantityValues !== undefined && rows[i].quantityValues !== null) {
							for (k = rows[i].quantityValues.length; k--;) totalQ = totalQ + rows[i].quantityValues[k] - 0;
							rows[i].quantityValues.push(totalQ)
						}
						if (totalQ === 0) {
							delete rows[i].quantityValues; // HOURS
							delete rows[i].priceValues;    // PRICE
						}
					}
				} catch (er) {
					alert("ROW SCOPE:" + er);
				}

				rows.unshift(marginRow);

				block.rows = rows;
				_cl("A BLOCK:" + JSON.stringify(block));
				blocks.push(block);
			}

			blocks.sort((a, b) => (a.header > b.header) ? 1 : -1);
			return blocks;
		} catch (e) {
			alert("generateEmployeeGroups" + e);
		}
	},

	///// EMPLOYEE  MODE

	helpGetTotalData: function (cmp, incomeData, expenseData) {
		try {
			let rootApp = cmp.get("v.rootApp");
			let totalData = [];
			let i, j;

			let incomeTotal;

			if (incomeData.length > 0) {
				incomeTotal = JSON.parse(JSON.stringify(incomeData[0]));
				for (let i = 0; i < incomeTotal.rowValues.length; i++) incomeTotal.rowValues[i].v = 0;
				incomeTotal.title = 'income total';
			}

			let expenseTotal;
			if (expenseData.length > 0) {
				expenseTotal = JSON.parse(JSON.stringify(expenseData[0]));
				for (i = 0; i < expenseTotal.rowValues.length; i++) expenseTotal.rowValues[i].v = 0;
				expenseTotal.title = 'expense total';
			}

			for (i = incomeData.length; i--;) {
				for (j = 0; j < incomeData[i].rowValues.length; j++) {
					incomeTotal.rowValues[j].v += incomeData[i].rowValues[j].v - 0;
				}
			}

			for (i = expenseData.length; i--;) {
				for (j = 0; j < expenseData[i].rowValues.length; j++) {
					expenseTotal.rowValues[j].v += expenseData[i].rowValues[j].v - 0;
				}
			}

			let marginTotal;
			try {
				if (incomeTotal !== undefined && expenseTotal !== undefined) {
					marginTotal = JSON.parse(JSON.stringify(!incomeTotal ? expenseTotal : incomeTotal));
					for (i = 0; i < marginTotal.rowValues.length; i++) {
						marginTotal.rowValues[i].v = incomeTotal.rowValues[i].v - expenseTotal.rowValues[i].v;
					}
					marginTotal.title = _isInvalid(rootApp.cb4__Tag2__r.cb4__Text5__c) ? 'margin total' : rootApp.cb4__Tag2__r.cb4__Text5__c + ' total';
				}
			} catch (e) {
				alert('margin total: ' + e)
			}

			if (incomeData.length > 0) totalData.push(incomeTotal);
			if (expenseData.length > 0) totalData.push(expenseTotal);
			if (marginTotal !== null) totalData.push(marginTotal);
			cmp.set("v.totalData", totalData);
		} catch (e) {
			alert("helpGetTotalData:" + e);
		}
	}
	,
	/**
	 * @param rows CBRow[]
	 * @param type type of amount ("v" - value, "r" - rate, "u" - unit)
	 * @param allMap
	 */
	arrayToObjects: function (rows, type, allMap) {
		const contr = 100;
		try {
			for (let i = 0; i < rows.length; i++) {
				rows[i].accName = _isInvalid(rows[i].account) ? undefined : allMap[rows[i].account].substr(0, contr);
				rows[i].appName = _isInvalid(rows[i].app) ? undefined : allMap[rows[i].app].substr(0, contr);
				rows[i].dim5Name = _isInvalid(rows[i].dim5) || _isInvalid(allMap[rows[i].dim5]) ? undefined : allMap[rows[i].dim5].substr(0, contr);
				rows[i].accTag5 = _isInvalid(rows[i].accName) ? undefined : _isInvalid(rows[i].dim5Name) ? undefined : rows[i].accName.split(':')[0] + ' ' + rows[i].dim5Name;
				rows[i].dim6Name = _isInvalid(rows[i].dim6) || _isInvalid(allMap[rows[i].dim6]) ? undefined : allMap[rows[i].dim6].substr(0, contr);
				rows[i].dim7Name = _isInvalid(rows[i].dim7) || _isInvalid(allMap[rows[i].dim7]) ? undefined : allMap[rows[i].dim7].substr(0, contr);
				rows[i].dim8Name = _isInvalid(rows[i].dim8) || _isInvalid(allMap[rows[i].dim8]) ? undefined : allMap[rows[i].dim8].substr(0, contr);
				rows[i].dim9Name = _isInvalid(rows[i].dim9) || _isInvalid(allMap[rows[i].dim9]) ? undefined : allMap[rows[i].dim9].substr(0, contr);
				rows[i].dim10Name = _isInvalid(rows[i].dim10) || _isInvalid(allMap[rows[i].dim10]) ? undefined : allMap[rows[i].dim10].substr(0, contr);
				rows[i].dim6HeadName = _isInvalid(rows[i].dim6Head) || _isInvalid(allMap[rows[i].dim6Head]) ? undefined : allMap[rows[i].dim6Head].substr(0, contr);
				rows[i].dim7HeadName = _isInvalid(rows[i].dim7Head) || _isInvalid(allMap[rows[i].dim7Head]) ? undefined : allMap[rows[i].dim7Head].substr(0, contr);
				rows[i].dim8HeadName = _isInvalid(rows[i].dim8Head) || _isInvalid(allMap[rows[i].dim8Head]) ? undefined : allMap[rows[i].dim8Head].substr(0, contr);
				rows[i].dim9HeadName = _isInvalid(rows[i].dim9Head) || _isInvalid(allMap[rows[i].dim9Head]) ? undefined : allMap[rows[i].dim9Head].substr(0, contr);
				rows[i].dim10HeadName = _isInvalid(rows[i].dim10Head) || _isInvalid(allMap[rows[i].dim10Head]) ? undefined : allMap[rows[i].dim10Head].substr(0, contr);
				let a = [];
				let rv = rows[i].rowValues;
				for (let j = 0; j < rv.length; j++) a.push({[type]: rv[j]});
				rows[i].rowValues = a;
			}
		} catch (e) {
			alert("arrayToObjects error: " + e);
		}
		return rows;
	}
	,

	helpGetMainAppSO: function (cmp) {
		let action = cmp.get("c.getInitialSOServer");
		action.setCallback(this, function (response) {
			_cl('helpGetMainAppSO callback', 'cyan');
			let state = response.getState();
			let options;
			if (state === "SUCCESS") {
				options = response.getReturnValue();
				let usersIdNameMap = {};
				options.user.forEach(function (currUser) {
					usersIdNameMap[currUser.value] = currUser.title;
					_cl('>>>>>>> =  ' + JSON.stringify(currUser), 'pink');
				})
				cmp.set("v.usersNameIdList", usersIdNameMap);
				if (cmp.get("v.doDownloadExcelOnload")) {
					this.helpDownloadExcelSplitBySheets(cmp);
					cmp.set("v.doDownloadExcelOnload", false);
				}
				_hideSpinner(cmp);
			} else {
				_cl('Server Error', 'red');
				_RequestError(response, _TEXT.APPS.FAILED_INITIAL);
			}
		});
		$A.enqueueAction(action);
	}
	,

	helpGetDimsNames: function (cmp) {
		let action = cmp.get("c.getExtraDimensionsSOServer");
		action.setParams({
			"appId": cmp.get("v.app.Id")
		});
		action.setCallback(this, function (response) {
			_cl('helpGetDimsNames callback', 'cyan');
			let state = response.getState();
			if (state === "SUCCESS") {
				let result = response.getReturnValue();
				let resultProcessed = JSON.parse(JSON.stringify(result));
				try {
					_cl("keys == " + Object.keys(result), 'pink');

					for (let i = 4; i <= 10; i++) {
						let currDimName = resultProcessed['appdname' + i];
						if (!_isInvalid(currDimName)) {
							cmp.set("v.appDim" + i + "name", currDimName);
							_cl("Current dimName == " + currDimName, 'cyan');
						}
					}

				} catch (e) {
					alert(e);
				}
			} else {
				_RequestError(response, "getExtraDimensionsSOServer Failed", cmp);
			}
		});
		$A.enqueueAction(action);
	}
	,

	appsStructure: function (cmp) {
		let allApps = cmp.get("v.allApps");
		let mainAppId = cmp.get("v.recordId");

		let appsStructure = [];
		let mainAppObj = {};

		try {
			for (let i = 0; i < allApps.length; i++) {

				if (mainAppId === allApps[i].Id) {
					mainAppObj = allApps[i];
					allApps[i].indent = 0;
					if (!_isInvalid(mainAppObj.incomeLines)) mainAppObj.hasIncome = true;
					if (!_isInvalid(mainAppObj.expenseLines)) mainAppObj.hasExpense = true;
				}
			}
			for (let i = 0; i < allApps.length; i++) {
				if (mainAppId === allApps[i].cb4__Tag1__c) {
					allApps[i].indent = 2;
					if (!_isInvalid(allApps[i].incomeLines)) {
						mainAppObj.hasIncome = true;
						allApps[i].hasIncome = true;
					};
					if (!_isInvalid(allApps[i].expenseLines)){
						mainAppObj.hasExpense = true;
						allApps[i].hasExpense = true;
					};

					appsStructure.push(allApps[i]);                // put second level

					for (let j = 0; j < allApps.length; j++) {
						if (allApps[i].Id === allApps[j].cb4__Tag1__c) {
							allApps[j].indent = 4;
							if (!_isInvalid(allApps[j].incomeLines)) {
								mainAppObj.hasIncome = true;
								allApps[i].hasIncome = true;
								allApps[j].hasIncome = true;
							}
							if (!_isInvalid(allApps[j].expenseLines)) {
								mainAppObj.hasExpense = true;
								allApps[i].hasExpense = true;
								allApps[j].hasExpense = true;
							}
							appsStructure.push(allApps[j]);                //put third level

							for (let k = 0; k < allApps.length; k++) {
								if (allApps[j].Id === allApps[k].cb4__Tag1__c) {
									allApps[k].indent = 6;
									if (!_isInvalid(allApps[k].incomeLines)) {
										mainAppObj.hasIncome = true;
										allApps[i].hasIncome = true;
										allApps[j].hasIncome = true;
										allApps[k].hasIncome = true;
									}
									if (!_isInvalid(allApps[k].expenseLines)) {
										mainAppObj.hasExpense = true;
										allApps[i].hasExpense = true;
										allApps[j].hasExpense = true;
										allApps[k].hasExpense = true;
									}
									appsStructure.push(allApps[k]);          //put fourth level

									for (let m = 0; m < allApps.length; m++) {
										if (allApps[k].Id === allApps[m].cb4__Tag1__c) {
											allApps[m].indent = 8;
											if (!_isInvalid(allApps[m].incomeLines)) {
												mainAppObj.hasIncome = true;
												allApps[i].hasIncome = true;
												allApps[j].hasIncome = true;
												allApps[k].hasIncome = true;
												allApps[m].hasIncome = true;
											}
											if (!_isInvalid(allApps[m].expenseLines)) {
												mainAppObj.hasExpense = true;
												allApps[i].hasExpense = true;
												allApps[j].hasExpense = true;
												allApps[k].hasExpense = true;
												allApps[m].hasExpense = true;
											}
											appsStructure.push(allApps[m]);   //put fifth level
										}
									}
								}
							}
						}
					}
				}
			}
			appsStructure.unshift(mainAppObj);  // put main level

			cmp.set("v.appsStructure", appsStructure);

		} catch (e) {
			alert(e);
		}

		// --> DEBUGGING
		appsStructure.forEach(function (currAppStr, index) {
			_cl(JSON.stringify(currAppStr.cb4__TagLabel__c +
				'  >>> Inc = ' + currAppStr.hasIncome +
				'  >>> Exp = ' + currAppStr.hasExpense), "lightgreen");
			// _cl(index + "  Structure  " + JSON.stringify(currAppStr), "pink");
		});
		// --< DEBUGGING
	}
	,

	helpGetAdditionalReferences: function (cmp) {
		function callback1() {
			_cl('getPriceQuantityObjectServer callback', 'cyan');
		}
		function callback2() {
			_cl('getEmployeeRateObjectServer callback', 'cyan');
		}
		_CBRequest(cmp, "c.getPriceQuantityObjectServer", null, "v.priceQuantityObject", callback1, null, 'P/Q ERROR', false);
		_CBRequest(cmp, "c.getEmployeeRateObjectServer", null, "v.employeeRateObject", callback2, null, 'E/R ERROR', false);
	},

	//////////   EXCEL   ///////////

	helpShowExcelPanel: function () {
		let exPanel = $("#excelPanel");
		if (exPanel.css('right') === '-350px') {
			exPanel.animate({right: '0', opacity: 1});
		} else {
			exPanel.animate({right: '-350px', opacity: 0.9});
		}
	}
	,

	helpDownloadExcelConsolidated: function (cmp, income, expense) {
		//console.clear();

		try {
			// PREPARATION
			let exStyle = this.getExcelStyle(); // styles
			// excel columns map
			let abc = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'AA', 'AB'];


			// data
			let tableHeaders = cmp.get("v.headers");
			let groupFilter = cmp.get("v.groupFilter");
			let allAccAndDims = cmp.get('v.allAccAndDims');
			let dimNames = {};

			let i, f;
			for (i = 0; i < groupFilter.length; i++) {
				f = groupFilter[i]; // CBSO
				if (_isInvalid(f) || f.title === 'Account' || f.title === 'Account SubType' || f.title === 'Product' || f.title === 'Employee') continue;
				dimNames[f.value] = f.title;
			} // {"title":"CB_FF1","value":"dim6Name"}
			// data

			let workbook = new ExcelJS.Workbook();
			let sheetName = 'BUDGET';
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

			if (dimNames.dim6Name != null) columns.push({header: dimNames.dim6Name, key: 'd6', width: 23}); //5?
			if (dimNames.dim7Name != null) columns.push({header: dimNames.dim7Name, key: 'd7', width: 23}); //6?
			if (dimNames.dim8Name != null) columns.push({header: dimNames.dim8Name, key: 'd8', width: 23}); //7?
			if (dimNames.dim9Name != null) columns.push({header: dimNames.dim9Name, key: 'd9', width: 23}); //8?
			if (dimNames.dim10Name != null) columns.push({header: dimNames.dim10Name, key: 'd10', width: 23}); //9?

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
			if (dimNames.dim6Name != null) startTotalPosition++;
			if (dimNames.dim7Name != null) startTotalPosition++;
			if (dimNames.dim8Name != null) startTotalPosition++;
			if (dimNames.dim9Name != null) startTotalPosition++;
			if (dimNames.dim10Name != null) startTotalPosition++;
			let endTotalPosition = startTotalPosition + numberOfColumns - 1; // index of the last value column for row total
			startTotalPosition = abc[startTotalPosition];// column 'E' for example
			endTotalPosition = abc[endTotalPosition];// column 'T' for example
			// COLUMNS CALCULATIONS
			i = 0; // index of the row
			// GLOBAL TOTALS
			let globalTotals = cmp.get("v.totalData");
			if (globalTotals.length > 0) globalTotals.forEach(function (line) {
				if (line === undefined) return;
				let r = {}; // one excel row
				r['type'] = line.title.toUpperCase();
				r['idx'] = ++i;
				const k = i + 1;
				r['total'] = {formula: 'SUM(' + startTotalPosition + k + ':' + endTotalPosition + k + ')'};
				for (let j = 0; j < tableHeaders.length; j++) r[tableHeaders[j]] = parseFloat(line.rowValues[j]['v']);
				worksheet.addRow(r);

				worksheet.getRow(k).eachCell({includeEmpty: true}, function (cell, colNumber) {
					cell.fill = exStyle.globalTotalFill;
					cell.border = exStyle.simpleBorders;
					cell.font = exStyle.appTotalFont;
				});
			});
			// GLOBAL TOTALS


			// TABLE ROWS

			//Income section
			if (income.length > 0) income.forEach(function (line) { // line  - is a Budget App line
				let r = {}; // one excel row
				r['type'] = 'Income'; //1
				r['title'] = _isInvalid(line.title) ? ' ' : line.title; //2
				if (!_isInvalid(line.appName)) {
					r['title'] = line.appName;
					r['type'] = ''; //1
				} //2.1
				r['acc'] = line.accName; // 3
				r['desc'] = line.type === 'groupTotal' ? '' : line.description; //4
				r['d6'] = allAccAndDims[line.dim6]; //5?
				r['d7'] = allAccAndDims[line.dim7]; //6?
				r['d8'] = allAccAndDims[line.dim8]; //7?
				r['d9'] = allAccAndDims[line.dim9]; //8?
				r['d10'] = allAccAndDims[line.dim10];//9?
				r['idx'] = ++i;

				for (let j = 0; j < tableHeaders.length; j++) r[tableHeaders[j]] = parseFloat(line.rowValues[j]['v']);
				const k = i + 1;
				r['total'] = {formula: 'SUM(' + startTotalPosition + k + ':' + endTotalPosition + k + ')'};

				worksheet.addRow(r);

				worksheet.getRow(k).eachCell({includeEmpty: true}, function (cell, colNumber) {
					cell.fill = exStyle.incomeFill;
					cell.border = exStyle.simpleBorders;
				});

				if (!_isInvalid(line.type)) {
					if (line.type === 'subTotal') {
						worksheet.getRow(k).eachCell({includeEmpty: true}, function (cell, colNumber) {
							cell.fill = exStyle.appTotalFill;
							cell.border = exStyle.simpleBorders;
							cell.font = exStyle.appTotalFont;
						});
					}
					if (line.type === 'groupTotal') {
						worksheet.getRow(k).eachCell({includeEmpty: true}, function (cell, colNumber) {
							cell.fill = exStyle.groupTotalFill;
							cell.border = exStyle.simpleBorders;
							cell.font = exStyle.appTotalFont;
						});
					}
				}
			});

			//Expense section
			if (expense.length > 0) expense.forEach(function (line) {
				let r = {}; // one excel row
				r['type'] = 'Expense'; //1
				r['title'] = _isInvalid(line.title) ? ' ' : line.title; //2
				if (!_isInvalid(line.appName)) {
					r['title'] = line.appName;
					r['type'] = ''; //1
				} //2.1
				r['acc'] = line.accName; // 3
				r['desc'] = line.type === 'groupTotal' ? '' : line.description; //4
				r['d6'] = allAccAndDims[line.dim6]; //5?
				r['d7'] = allAccAndDims[line.dim7]; //6?
				r['d8'] = allAccAndDims[line.dim8]; //7?
				r['d9'] = allAccAndDims[line.dim9]; //8?
				r['d10'] = allAccAndDims[line.dim10];//9?
				r['idx'] = ++i;

				for (let j = 0; j < tableHeaders.length; j++) r[tableHeaders[j]] = parseFloat(line.rowValues[j]['v']);

				const k = i + 1;
				r['total'] = {formula: 'SUM(' + startTotalPosition + k + ':' + endTotalPosition + k + ')'};

				worksheet.addRow(r);

				worksheet.getRow(k).eachCell({includeEmpty: true}, function (cell, colNumber) {
					cell.fill = exStyle.expenseFill;
					cell.border = exStyle.simpleBorders;
				});

				if (!_isInvalid(line.type)) {
					if (line.type === 'subTotal') {
						worksheet.getRow(k).eachCell({includeEmpty: true}, function (cell, colNumber) {
							cell.fill = exStyle.appTotalFill;
							cell.border = exStyle.simpleBorders;
							cell.font = exStyle.appTotalFont;
						});
					}
					if (line.type === 'groupTotal') {
						worksheet.getRow(k).eachCell({includeEmpty: true}, function (cell, colNumber) {
							cell.fill = exStyle.groupTotalFill;
							cell.border = exStyle.simpleBorders;
							cell.font = exStyle.appTotalFont;
						});
					}
				}
			});

			worksheet.getRow(1).eachCell({includeEmpty: false}, function (cell, cellNumber) { // header
				cell.font = exStyle.headerFont;
				cell.border = exStyle.headerBorder;
				cell.fill = exStyle.headerFill;
			});

			// index column
			worksheet.getColumn('idx').fill = exStyle.headerFill;
			worksheet.getColumn('idx').font = exStyle.headerFont;
			// TABLE ROWS

			workbook.xlsx.writeBuffer().then(buffer => saveAs(new Blob([buffer]), cmp.get('v.rootApp.cb4__TagLabel__c') + ' Consolidated' + '.xlsx')).catch(err => alert('Error writing excel export' + err));
			this.helpBackToMainTable(cmp);
		} catch (e) {
			alert(e)
		}
	},

	helpDownloadExcelSplitBySheets: function (cmp) {

		try {

			//--> PREPARATION

			let exStyle = this.getExcelStyle(); // styles
			// excel columns map
			let abc = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'AA', 'AB'];

			//--> data
			let appsStructure = cmp.get("v.appsStructure");
			let usersIdNameMap = cmp.get("v.usersNameIdList");
			let appDim6name = cmp.get("v.appDim6name");
			let appDim7name = cmp.get("v.appDim7name");
			let appDim8name = cmp.get("v.appDim8name");
			let appDim9name = cmp.get("v.appDim9name");
			let appDim10name = cmp.get("v.appDim10name");
			let tableHeaders = cmp.get("v.headers");
			let groupFilter = cmp.get("v.groupFilter");
			let dimNames = {};
			let dataRowsCounter = 2;

			let i, f, key, app;
			for (i = 0; i < groupFilter.length; i++) {
				f = groupFilter[i];
				if (_isInvalid(f) || f.title === 'Account' || f.title === 'Account SubType' || f.title === 'Product' || f.title === 'Employee') continue;
				dimNames[f.value] = f.title;
			} // {"title":"CB_FF1","value":"dim6Name"}

			let workbook = new ExcelJS.Workbook();

			if (appsStructure.length !== 1) {

				/**
				 * APPS MAIN LIST SHEET
				 */

				let appsListSheet = workbook.addWorksheet('Apps List', {
					views: [
						{state: 'frozen', ySplit: 1, xSplit: 0}
					],
					properties: {showGridLines: true, tabColor: {argb: 'ffffb3'}}
				});

				//--> HEADER

				let columns = [];
				columns.push({header: 'App', key: 'app', width: 43}); // 1st col
				columns.push({
					header: 'Income',
					key: 'inc',
					style: {numFmt: '$ #,##0.00;[Red]($ #,##0.00)'},
					width: 18
				}); // 2nd col
				columns.push({
					header: 'Expense',
					key: 'exp',
					style: {numFmt: '$ #,##0.00;[Red]($ #,##0.00)'},
					width: 18
				}); // 3d col
				columns.push({
					header: 'Total',
					key: 'total',
					style: {numFmt: '$ #,##0.00;[Red]($ #,##0.00)'},
					width: 18
				}); // 4th col
				columns.push({header: 'Period', key: 'period', width: 12});  // 5th col
				columns.push({header: 'Owner', key: 'owner', width: 20});    // 6th col
				columns.push({header: 'Status', key: 'status', width: 14});  // 7th col
				columns.push({header: 'Department', key: 'dep', width: 20}); // 8th col
				columns.push({header: 'Template', key: 'dep', width: 22});   // 9th col

				for (let d = 6; d <= 10; d++) {
					let currDimName = cmp.get("v.appDim" + d + "name");
					if (!_isInvalid(currDimName)) columns.push({header: currDimName, key: 'dep', width: 20}); // 10...14th col
				}
				columns.push({header: 'Description', key: 'desc', width: 25}); //10...15th col

				appsListSheet.columns = columns;
				appsListSheet.getColumn(appsListSheet.actualColumnCount).font = exStyle.totalFont;

				//--> HEADER STYLE

				appsListSheet.getRow(1).height = exStyle.headerHeight;
				appsListSheet.getRow(1).eachCell({includeEmpty: false}, function (cell) { // header
					cell.font = exStyle.headerFont;
					cell.alignment = exStyle.headerAlignment;
					cell.fill = exStyle.headerFill;
					cell.border = exStyle.simpleGreyBorders;
				});

				//--> COLUMNS DATA

				let appsNames = ['App'];          // 1st col
				let appsIncome = ['Income'];      // 4th col
				let appsExpense = ['Expense'];    // 5th col
				let appsTotal = ['Total'];        // 6th col
				let appsPeriod = ['Period'];      // 7th col
				let appsOwners = ['Owner'];       // 2st col
				let appsStatus = ['Status'];      // 3nd col
				let appsDep = ['Department'];     // 8th col
				let appsTempl = ['Template'];     // 9th col
				let appsDim6 = [appDim6name];     // 10th col
				let appsDim7 = [appDim7name];     // 10...11th col
				let appsDim8 = [appDim8name];     // 10...12th col
				let appsDim9 = [appDim9name];     // 10...13th col
				let appsDim10 = [appDim10name];   // 10...14th col
				let appsDesc = ['Description'];   // 10...15th col

				let appsNameList = [];
				appsStructure.forEach(function (currApp) {

					let appName = currApp.cb4__TagLabel__c;
					appsNameList.push(appName);

					appsNames.push(appName);
					appsListSheet.getCell('A' + dataRowsCounter).alignment = {indent: currApp.indent};
					appsOwners.push(usersIdNameMap[currApp.OwnerId]); //need to add check on null Id
					appsStatus.push(currApp.cb4__Status__c);
					appsIncome.push(Math.round(currApp.cb4__Decimal1__c * 100) / 100);
					appsExpense.push(Math.round(currApp.cb4__Decimal2__c * 100) / 100);
					appsTotal.push({formula: 'B' + dataRowsCounter + '-C' + dataRowsCounter});
					appsPeriod.push(currApp.cb4__Tag3Name__c);
					appsDep.push(currApp.cb4__Tag4Name__c);
					appsTempl.push(currApp.cb4__Tag2Name__c);

					if (!_isInvalid(appDim6name)) appsDim6.push(currApp.cb4__Tag6Name__c);
					if (!_isInvalid(appDim7name)) appsDim7.push(currApp.cb4__Tag7Name__c);
					if (!_isInvalid(appDim8name)) appsDim8.push(currApp.cb4__Tag8Name__c);
					if (!_isInvalid(appDim9name)) appsDim9.push(currApp.cb4__Tag9Name__c);
					if (!_isInvalid(appDim10name)) appsDim9.push(currApp.cb4__Tag10Name__c);

					appsDesc.push(currApp.cb4__Text3__c);
					dataRowsCounter++;
				});

				let colCounter = 1;
				appsListSheet.getColumn(colCounter++).values = appsNames;    // 1st col
				appsListSheet.getColumn(colCounter++).values = appsIncome;   // 2nd col
				appsListSheet.getColumn(colCounter++).values = appsExpense;  // 3d col
				appsListSheet.getColumn(colCounter++).values = appsTotal;    // 4th col
				appsListSheet.getColumn(colCounter++).values = appsPeriod;   // 5th col
				appsListSheet.getColumn(colCounter++).values = appsOwners;   // 6th col
				appsListSheet.getColumn(colCounter++).values = appsStatus;   // 7th col
				appsListSheet.getColumn(colCounter++).values = appsDep;      // 8th col
				appsListSheet.getColumn(colCounter++).values = appsTempl;    // 9th col

				if (!_isInvalid(appDim6name)) appsListSheet.getColumn(colCounter++).values = appsDim6;   // 10th col
				if (!_isInvalid(appDim7name)) appsListSheet.getColumn(colCounter++).values = appsDim7;   // 10...11th col
				if (!_isInvalid(appDim8name)) appsListSheet.getColumn(colCounter++).values = appsDim8;   // 10...12th col
				if (!_isInvalid(appDim9name)) appsListSheet.getColumn(colCounter++).values = appsDim9;   // 10...13th col
				if (!_isInvalid(appDim10name)) appsListSheet.getColumn(colCounter++).values = appsDim10; // 10...14th col

				appsListSheet.getColumn(colCounter).values = appsDesc;   // 10...15th col


				//--> STYLE
				for (let r = 2; r < dataRowsCounter; r++) {
					appsListSheet.getRow(r).eachCell({includeEmpty: true}, function (cell, colNumber) {
						if (colNumber <= colCounter) {
							cell.fill = exStyle.mainAppListFill;
							cell.border = exStyle.simpleGreyBorders;
						}
					});
					appsListSheet.getCell('A' + r).value = {
						text: appsNameList[r - 2],
						hyperlink: '#\'' + appsNameList[r - 2] + '\'!A1'
					};
				}
			}

			/**
			 * APPS SHEETS
			 */

				//--> COLUMNS COORDINATES

			let firstValueColumn = 6; // calculation below
			let numberOfValueColumns = 0;// number of value columns (4-12), calculation below
			let globalTotalColumn = 0; // calculation below

			//--> TABLE COLUMNS

			let columnsAppSh = [];
			columnsAppSh.push({header: 'Title', key: 'title', width: 30}); // 1st col
			columnsAppSh.push({header: 'Type', key: 'type', width: 6});// 2nd col
			columnsAppSh.push({header: 'Account', key: 'acc', width: 23}); // 3rd col
			columnsAppSh.push({header: 'Description', key: 'desc', width: 23}); //4th col

			if (dimNames.dim6Name != null) {
				columnsAppSh.push({header: dimNames.dim6Name, key: 'd6', width: 23});
				++firstValueColumn;
			} //5?
			if (dimNames.dim7Name != null) {
				columnsAppSh.push({header: dimNames.dim7Name, key: 'd7', width: 23});
				++firstValueColumn;
			} //6?
			if (dimNames.dim8Name != null) {
				columnsAppSh.push({header: dimNames.dim8Name, key: 'd8', width: 23});
				++firstValueColumn;
			} //7?
			if (dimNames.dim9Name != null) {
				columnsAppSh.push({header: dimNames.dim9Name, key: 'd9', width: 23});
				++firstValueColumn;
			} //8?
			if (dimNames.dim10Name != null) {
				columnsAppSh.push({header: dimNames.dim10Name, key: 'd10', width: 23});
				++firstValueColumn;
			} //9?

			columnsAppSh.push({header: '#', key: 'idx', width: 3}); // index column (can be 5th up to 10th)

			tableHeaders.forEach(function (h) {
				numberOfValueColumns++;
				columnsAppSh.push({header: h, key: h, width: 14, style: {numFmt: '$ #,##0.00;[Red]($ #,##0.00)'}}); // simple columns with amounts
			});
			columnsAppSh.push({ // row total column
				header: 'Total',
				key: 'total',
				width: 15,
				style: {numFmt: '$ #,##0.00;[Red]($ #,##0.00)'}
			});
			globalTotalColumn = firstValueColumn + numberOfValueColumns;

			appsStructure.forEach(function (currApp) {

				let appName = currApp.cb4__TagLabel__c;

				let excelSheet = workbook.addWorksheet(appName.substr(0, 30), {
					views: [
						{state: 'frozen', ySplit: 5, xSplit: 0}
					],
					properties: {showGridLines: true, tabColor: {argb: 'cce6ff'}}
				});

				excelSheet.columns = columnsAppSh;
				excelSheet.getColumn(excelSheet.actualColumnCount).font = exStyle.totalFont;

				//--> ROW COORDINATES

				let firstIncomeRowValue = 7; // row after second headRow
				let firstExpenseRowValue = firstIncomeRowValue;
				let incomeRowCounter;
				let expenseRowCounter;

				//--> GENERAL SECTION

				let incomeTotalRow = [];
				incomeTotalRow[1] = 'INCOME TOTAL';
				for (let i = 2; i < firstValueColumn + 5; i++) {
					incomeTotalRow[i] = '';
				}
				for (let v = firstValueColumn; v < (firstValueColumn + numberOfValueColumns); v++) {
					incomeTotalRow[v] = 0;
				}
				excelSheet.addRow(incomeTotalRow);

				let expenseTotalRow = [];
				expenseTotalRow[1] = 'EXPENSE TOTAL';
				for (let i = 2; i < firstValueColumn; i++) {
					expenseTotalRow[i] = '';
				}
				for (let v = firstValueColumn; v < (firstValueColumn + numberOfValueColumns); v++) {
					expenseTotalRow[v] = 0;
				}
				excelSheet.addRow(expenseTotalRow);

				let marginTotalRow = [];
				marginTotalRow[1] = 'MARGIN TOTAL';
				for (let i = 2; i < firstValueColumn; i++) {
					marginTotalRow[i] = '';
				}
				for (let v = firstValueColumn; v < (firstValueColumn + numberOfValueColumns); v++) {
					marginTotalRow[v] = 0;
				}
				excelSheet.addRow(marginTotalRow);

				let generalValue = [];
				generalValue[1] = appName;
				generalValue[2] = "";
				generalValue[3] = "";
				generalValue[4] = (currApp.hasOwnProperty('cb4__Text3__c')) ? currApp.cb4__Text3__c : "-";

				for (let h = 5; h <= (firstValueColumn + numberOfValueColumns); h++) {
					generalValue[h] = "";
				}
				excelSheet.addRow(generalValue);

				//--> INCOME SECTION

				if (currApp.hasIncome) {

					incomeRowCounter = firstIncomeRowValue; //count all income rows which have values

					let incValue = ['Income'];
					for (let i = 1; i < (firstValueColumn + numberOfValueColumns); i++) {
						incValue[i] = "";
					}
					excelSheet.addRow(incValue);


					//--> Inc line

					if (!_isInvalid(currApp.incomeLines)) {

						for (let i = 0; i < currApp.incomeLines.length; i++) {
							let rowValues = [];
							for (let i = 1; i < (firstValueColumn + numberOfValueColumns); i++) { //add empty values to apply the style for all row
								rowValues[i] = "";
							}
							rowValues[1] = currApp.incomeLines[i].title;
							rowValues[2] = "Line";
							rowValues[3] = currApp.incomeLines[i].accName;
							rowValues[4] = (currApp.incomeLines[i].hasOwnProperty('description')) ? currApp.incomeLines[i].description : "-";

							let colCounter = 4;


							//--> Values of Analytic Dimensions

							if (dimNames.dim6Name != null) {
								++colCounter;
								if (currApp.incomeLines[i].dim6Name != null) rowValues[colCounter] = currApp.incomeLines[i].dim6Name;
							}
							if (dimNames.dim7Name != null) {
								++colCounter;
								if (currApp.incomeLines[i].dim7Name != null) rowValues[colCounter] = currApp.incomeLines[i].dim7Name;
							}
							if (dimNames.dim8Name != null) {
								++colCounter;
								if (currApp.incomeLines[i].dim8Name != null) rowValues[colCounter] = currApp.incomeLines[i].dim8Name;
							}
							if (dimNames.dim9Name != null) {
								++colCounter;
								if (currApp.incomeLines[i].dim9Name != null) rowValues[colCounter] = currApp.incomeLines[i].dim9Name;
							}
							if (dimNames.dim10Name != null) {
								++colCounter;
								if (currApp.incomeLines[i].dim10Name != null) rowValues[colCounter] = currApp.incomeLines[i].dim10Name;
							}
							++colCounter; //index column

							let lineValues = currApp.incomeLines[i].rowValues;
							for (let j = 0; j < (lineValues.length - 1); j++) {
								rowValues[++colCounter] = Math.round(lineValues[j].v * 100) / 100;
							}
							rowValues[++colCounter] =
								{formula: 'SUM(' + abc[firstValueColumn - 1] + '' + incomeRowCounter + ':' + abc[globalTotalColumn - 2] + '' + '' + incomeRowCounter + ')'};

							excelSheet.addRow(rowValues);
							++incomeRowCounter;
						}
					}

					//--> Inc Children App

					if (!_isInvalid(currApp.children)) {

						currApp.children.forEach(function (currChild) {
							if (currChild.hasIncome) {
								let childName = currChild.cb4__TagLabel__c;

								let rowValues = [];
								for (let i = 1; i < (firstValueColumn + numberOfValueColumns); i++) { //add empty values to apply the style for all row
									rowValues[i] = "";
								}
								rowValues[1] = childName;
								rowValues[2] = "App";
								rowValues[4] = (currChild.hasOwnProperty('cb4__Text3__c')) ? currChild.cb4__Text3__c : "-";

								let cellCounter = firstValueColumn;
								for (let v = firstValueColumn; v < (firstValueColumn + numberOfValueColumns + 1); v++) {
									rowValues[cellCounter++] = {formula: '\'' + childName + '\'!' + abc[v - 1] + '2'};
								}

								excelSheet.addRow(rowValues);
								++incomeRowCounter;
							}
						});
					}

					//--> Income Style

					for (let s = (firstIncomeRowValue - 1); s < incomeRowCounter; s++) {
						excelSheet.getRow(s).eachCell({includeEmpty: false}, function (cell) {
							cell.fill = exStyle.incomeFill;
							cell.border = exStyle.simpleGreyBorders;
						});
					}
					firstExpenseRowValue = ++incomeRowCounter;

					//--> INCOME TOTALS Formula

					for (let f = firstValueColumn; f < (firstValueColumn + numberOfValueColumns); f++) {
						let abcColumnName = abc[f - 1];
						excelSheet.getRow(2).getCell(f).value = {formula: 'SUM(' + abcColumnName + '' + firstIncomeRowValue + ':' + abcColumnName + '' + (incomeRowCounter - 2) + ')'};
					}

				}

				//--> EXPENSE SECTION


				if (currApp.hasExpense) {
					expenseRowCounter = firstExpenseRowValue; //count all expense rows which have values

					let expValue = ['Expense'];
					for (let i = 1; i < (firstValueColumn + numberOfValueColumns); i++) {
						expValue[i] = "";
					}
					excelSheet.addRow(expValue);


					//--> Exp own line

					if (!_isInvalid(currApp.expenseLines)) {

						for (let i = 0; i < currApp.expenseLines.length; i++) {
							let rowValues = [];
							for (let i = 1; i < (firstValueColumn + numberOfValueColumns); i++) { //add empty values to apply the style for all row
								rowValues[i] = "";
							}
							rowValues[1] = currApp.expenseLines[i].title;
							rowValues[2] = "Line";
							rowValues[3] = currApp.expenseLines[i].accName;
							rowValues[4] = (currApp.expenseLines[i].hasOwnProperty('description')) ? currApp.expenseLines[i].description : "-";

							let colCounter = 4;

							//--> Values of Analytic Dimensions
							if (dimNames.dim6Name != null) {
								++colCounter;
								if (currApp.expenseLines[i].dim6Name != null) rowValues[colCounter] = currApp.expenseLines[i].dim6Name;
							}
							if (dimNames.dim7Name != null) {
								++colCounter;
								if (currApp.expenseLines[i].dim7Name != null) rowValues[colCounter] = currApp.expenseLines[i].dim7Name;
							}
							if (dimNames.dim8Name != null) {
								++colCounter;
								if (currApp.expenseLines[i].dim8Name != null) rowValues[colCounter] = currApp.expenseLines[i].dim8Name;
							}
							if (dimNames.dim9Name != null) {
								++colCounter;
								if (currApp.expenseLines[i].dim9Name != null) rowValues[colCounter] = currApp.expenseLines[i].dim9Name;
							}
							if (dimNames.dim10Name != null) {
								++colCounter;
								if (currApp.expenseLines[i].dim10Name != null) rowValues[colCounter] = currApp.expenseLines[i].dim10Name;
							}
							++colCounter; // Index Column

							let lineValues = currApp.expenseLines[i].rowValues;
							for (let j = 0; j < (lineValues.length - 1); j++) {
								rowValues[++colCounter] = Math.round(lineValues[j].v * 100) / 100;
							}
							rowValues[++colCounter] =
								{formula: 'SUM(' + abc[firstValueColumn - 1] + '' + expenseRowCounter + ':' + abc[globalTotalColumn - 2] + '' + '' + expenseRowCounter + ')'};

							excelSheet.addRow(rowValues);
							expenseRowCounter++;
						}
					}

					//--> Exp Children App

					if (!_isInvalid(currApp.children)) {

						currApp.children.forEach(function (currChild) {
							if (currChild.hasExpense) {
								let childName = currChild.cb4__TagLabel__c;
								let rowValues = [];
								for (let i = 1; i < (firstValueColumn + numberOfValueColumns); i++) { //add empty values to apply the style for all row
									rowValues[i] = "";
								}
								rowValues[1] = childName;
								rowValues[2] = "App";
								rowValues[4] = (currChild.hasOwnProperty('cb4__Text3__c')) ? currChild.cb4__Text3__c : "-";

								let cellCounter = firstValueColumn;
								for (let v = firstValueColumn; v < (firstValueColumn + numberOfValueColumns + 1); v++) {
									rowValues[cellCounter++] = {formula: '\'' + childName + '\'!' + abc[v - 1] + '3'};
								}

								excelSheet.addRow(rowValues);
								expenseRowCounter++;
							}
						});
					}
					//--> Expense Style
					for (let s = (firstExpenseRowValue - 1); s < expenseRowCounter; s++) {
						excelSheet.getRow(s).eachCell({includeEmpty: false}, function (cell) {
							cell.fill = exStyle.expenseFill;
							cell.border = exStyle.simpleGreyBorders;
						});
					}

					//--> EXPENSE TOTALS Formula

					for (let f = firstValueColumn; f < (firstValueColumn + numberOfValueColumns); f++) {
						let abcColumnName = abc[f - 1];
						excelSheet.getRow(3).getCell(f).value =
							{formula: 'SUM(' + abcColumnName + '' + firstExpenseRowValue + ':' + abcColumnName + '' + (expenseRowCounter - 1) + ')'};
					}
				}

				//--> INCOME Global Total

				excelSheet.getRow(2).getCell(globalTotalColumn).value =
					{formula: 'SUM(' + abc[firstValueColumn - 1] + '2:' + abc[globalTotalColumn - 2] + '2)'};


				//--> EXPENSE Global Total

				excelSheet.getRow(3).getCell(globalTotalColumn).value = {formula: 'SUM(' + abc[firstValueColumn - 1] + '3:' + abc[globalTotalColumn - 2] + '3)'};


				//--> MARGIN TOTAL Formulas

				for (let f = firstValueColumn; f <= (firstValueColumn + numberOfValueColumns); f++) {
					let abcColumnName = abc[f - 1];
					excelSheet.getRow(4).getCell(f).value =
						{formula: abcColumnName + '2-' + abcColumnName + '3'};
				}


				//--> COMMON STYLE

				let headRows = [1, 5];
				headRows.forEach(function (hRow) {
					excelSheet.getRow(hRow).height = exStyle.headerHeight;
					excelSheet.getRow(hRow).eachCell({includeEmpty: false}, function (cell, cellNumber) { // header
						cell.font = exStyle.headerFont;
						cell.alignment = exStyle.headerAlignment;
						cell.fill = exStyle.headerFill;
						cell.border = exStyle.simpleGreyBorders;
					});
				});

				for (let t = 2; t <= 4; t++) {
					excelSheet.getRow(t).eachCell({includeEmpty: false}, function (cell) {
						cell.fill = exStyle.globalTotalFill;
						cell.border = exStyle.simpleGreyBorders;
						cell.font = exStyle.totalFont;
					});
				}

				//--> Index column

				excelSheet.getColumn('idx').eachCell({includeEmpty: false}, function (cell, cellNumber) {
					if (cellNumber !== 1) {
						cell.value = cellNumber;
						cell.fill = exStyle.headerFill;
						cell.alignment = exStyle.headerAlignment;
					}
				});
				excelSheet.getColumn('idx').font = exStyle.headerFont;
			});


			workbook.xlsx.writeBuffer().then(buffer => saveAs(new Blob([buffer]), cmp.get('v.rootApp.cb4__TagLabel__c') + ' (Split by Sheets)' + '.xlsx')).catch(err => alert('Error writing excel export' + err));

		} catch
			(e) {
			alert(e)
		}
	}
	,


	getExcelStyle: function () {
		let r = {};

		/// --> Header of the table
		r.headerFill = {
			type: 'pattern',
			pattern: 'solid',
			fgColor: {argb: '142952'}
		};
		r.headerFont = {bold: true, color: {argb: 'FFFFFF'}}; // white bold
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
		r.headerHeight = 18;
		r.headerAlignment = {vertical: 'middle', horizontal: 'center'};
		/// <-- Header of the table

		r.totalFont = {bold: true, color: {argb: '000000'}}; // black bold
		r.appTotalFont = {bold: true, color: {argb: '000000'}}; // black bold
		r.mainAppListFill = {
			type: 'pattern',
			pattern: 'solid',
			fgColor: {argb: 'e6f7ff'}
		};
		r.globalTotalFill = {
			type: 'pattern',
			pattern: 'solid',
			fgColor: {argb: 'b3f1ff'}
		};
		r.incomeFill = {
			type: 'pattern',
			pattern: 'solid',
			fgColor: {argb: 'd3f6db'}
		};
		r.expenseFill = {
			type: 'pattern',
			pattern: 'solid',
			fgColor: {argb: 'fff2e6'}
		};
		r.appTotalFill = {
			type: 'pattern',
			pattern: 'solid',
			fgColor: {argb: '699be1'}
		};
		r.groupTotalFill = {
			type: 'pattern',
			pattern: 'solid',
			fgColor: {argb: 'b3caea'}
		};
		r.simpleBorders = {
			top: {style: "thin"},
			left: {style: "thin"},
			bottom: {style: "thin"},
			right: {style: "thin"}
		};
		r.simpleGreyBorders = {
			top: {style: 'thin', color: {argb: 'bfbfbf'}},
			left: {style: 'thin', color: {argb: 'bfbfbf'}},
			bottom: {style: 'thin', color: {argb: 'bfbfbf'}},
			right: {style: 'thin', color: {argb: 'bfbfbf'}}
		};
		r.numFormat = '$ #,##0.00;[Red]($ #,##0.00)';

		return r;
	}
	,

	helpBackToMainTable: function (cmp) {
		let appId = cmp.get("v.app.Id");
		function redirect(cmp, response) {
			_cl('helpBackToMainTable callback', 'cyan');
			const cmpName = response.getReturnValue();
			let param = {
				mode: 'table'
			};
			_CBRedirect.toComponent(cmpName, param);
		}
		_CBRequest(cmp, "c.getProperlyCmpNameServer", {"recordId": appId, "dimensionId": null, "createNewTag": false}, null, redirect, null, 'Redirect Error');
	},

});