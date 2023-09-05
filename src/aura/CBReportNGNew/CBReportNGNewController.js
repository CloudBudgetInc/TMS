({
	doInit: function (cmp, event, helper) {
		helper.helpGetReport(cmp);
		helper.helpGetTableHeaders(cmp);
		helper.helpGetReportColumnsServer(cmp);
		helper.helpGetDisplayGroups(cmp);
		helper.helpGetCBalances(cmp);//  _this.helpGenerateReportLines(cmp); _this.helpGetFilterSelectOptions(cmp); _this.helpRefreshReportData(cmp);
		//helper.helpGetReportWarningMessage(cmp);
		_showSpinner(cmp);
		let today = new Date();
		let dateTime = (today.getMonth() + 1) + '/' + today.getDate() + '/' + today.getFullYear() + ' ' + today.getHours() + ":" + today.getMinutes();
		cmp.set('v.pdfDate', dateTime);
	},

	showHideSimpleRows: function (cmp, event, helper) {
		helper.helpRefreshReportDataAfterSpinner(cmp);
	},

	savePreviousFilters: function (cmp, event, helper) {
		for (let i = 1; i <= 7; i++) cmp.set("v.d" + i + "filterOld", cmp.get("v.d" + i + "filter"));
	},

	applyFilter: function (cmp, event, helper) {
		if (!confirm('Apply filter?')) {
			for (let i = 1; i <= 7; i++) cmp.set("v.d" + i + "filter", cmp.get("v.d" + i + "filterOld"));
			return;
		}
		for (let i = 1; i <= 7; i++) cmp.set("v.d" + i + "filterOld", cmp.get("v.d" + i + "filter"));
		helper.helpRefreshReportDataAfterSpinner(cmp);
	},

	showModalToDownloadExcelForSpecificBDGs: function(cmp, evt, h) {
		let bdgSO = cmp.get('v.d5SO');
		bdgSO.sort();
		let bdgColumnsSO = [];
		for(let i= 0; i < bdgSO.length; i++){
			bdgColumnsSO.push({
				label : bdgSO[i],
				value : bdgSO[i]
			});
		}
		cmp.set('v.bdgSetSO', bdgColumnsSO);
		$A.util.removeClass(cmp.find("bdgSet"), "slds-hide");
	},
	downloadExcelForSelectedBDGs: function(cmp, evt, h) {
		alert('downloadExcelForSelectedBDGs handler');
	},
	downloadExcel: function (cmp, event, helper) {
		helper.helpDownloadExcel(cmp);
	},
	downloadAllToExcel: function (cmp, event, helper) {
		helper.helpDownloadAllToExcel(cmp);
	},
	downloadAllBySheetToExcel: function (cmp, evt, h) {
		let report = cmp.get("v.report");
		let workbook = new ExcelJS.Workbook();
		let repDepartments = cmp.get('v.d1SO');
		cmp.set("v.d2filter", null);
		cmp.set("v.d3filter", null);
		cmp.set("v.d4filter", null);
		cmp.set("v.d5filter", null);
		cmp.set("v.d6filter", null);
		cmp.set("v.d7filter", null);
		for(let f = 0; f < repDepartments.length; f++){
			cmp.set("v.d1filter", repDepartments[f]);

			// refresh data from the source
			let origin = JSON.parse(JSON.stringify(cmp.get("v.rowsOriginal")));

			let columns = JSON.parse(JSON.stringify(cmp.get("v.reportColumnsOriginal")));
			cmp.set("v.reportColumns", columns);

			let header = JSON.parse(JSON.stringify(cmp.get("v.tableHeadersOriginal")));
			cmp.set("v.tableHeaders", header);

			cmp.set("v.rows", origin);
			h.helpApplyDimensionFilter(cmp); // dimension filter
			if (cmp.get("v.rows").length === 0) {
				return;
			}
			h.helpCalculateColumnTotals(cmp); // vertical totals
			h.helpCalculateRowTotals(cmp); // horizontal total

			h.helpFormatNumbers(cmp); // formatting

			h.helpShowHideSimpleRows(cmp); // total rows only filter
			h.helpApplyColumnsFilter(cmp); // display only allowed columns filter

			/////// ADD SHEET TO EXCELL
			let tableRows = cmp.get('v.rows');
			let sheetName = repDepartments[f];

			let fixedColumns = report.cb4__FixedColumns__c;
			if (_isInvalid(fixedColumns)) fixedColumns = 1; else fixedColumns--;
			let tableHeaders = cmp.get("v.tableHeaders");
			sheetName = sheetName.substring(0, 30).replace(':', '\uA789');
			let worksheet = workbook.addWorksheet(sheetName, {
				views: [
					{state: 'frozen', ySplit: 1, xSplit: fixedColumns}
				]
			});

			// COLUMNS
			let arr = [];
			tableHeaders.forEach(function (h) {
				//arr.push({header: h, key: h, width: 16, style: {numFmt: '$ #,##0.00;[Red]($ #,##0.00)'}});
				if(h === 'Actual vs Budget YTD') {
					arr.push({header: h, key: h, width: 16, style: {numFmt: '#,##0.00;[Red](#,##0.00)'}});
				}else{
					arr.push({header: h, key: h, width: 16, style: {numFmt: '#,##0.00;[Black](#,##0.00)'}});
				}
			});
			worksheet.columns = arr;
			// COLUMNS

			let subTotalRowNumbers = [];
			let i = 2;

			// ROWS
			const n = cmp.get("v.numberOfTextColumns"); // the number of text columns
			tableRows.forEach(function (row, idx) {
				if (row.type === 'subTotal1' || row.type === 'subTotal2' || row.type === 'subTotal3' || row.type === 'subTotal4') subTotalRowNumbers.push(i);
				i++;

				let r = {}; // one row
				for (let j = 0; j < n; j++) r[tableHeaders[j]] = row["l" + (j + 1) + "Long"];

				let k = n;
				row.v.forEach(function (val) {
					r[tableHeaders[k]] = getRowAmount(val);
					k++;
				});

				worksheet.addRow(r);
			});

			function getRowAmount(val) {
				if (val === '-') return val;
				if (val.includes(' %')) parseFloat(val.replace(' %').replace(/,/g, '')) + ' %';
				return parseFloat(val.replace(/,/g, ''));
			}

			// ROWS

			const borderStyles = {
				top: {style: "thin"},
				left: {style: "thin"},
				bottom: {style: "thin"},
				right: {style: "thin"}
			};
			const headerBorderStyles = {
				top: {style: "thin"},
				left: {style: "thin"},
				bottom: {style: 'double', color: {argb: '005493'}},
				right: {style: "thin"}
			};
			const headerFill = {
				type: 'pattern',
				pattern: 'solid',
				fgColor: {argb: '0080DF'}
			};
			const totalFill = {
				type: 'pattern',
				pattern: 'solid',
				fgColor: {argb: '16325c'}
			};
			worksheet.eachRow({includeEmpty: true}, function (row, rowNumber) { // all rows
				row.eachCell({includeEmpty: true}, function (cell, cellNumber) {
					cell.border = borderStyles;
					cell.font = {color: {argb: '4a4a4a'}};
				});
			});
			worksheet.getRow(1).eachCell({includeEmpty: false}, function (cell, cellNumber) { // table header
				cell.font = {bold: true, color: {argb: 'FFFFFF'},};
				cell.border = headerBorderStyles;
				cell.fill = headerFill;
			});

			subTotalRowNumbers.forEach(function (index) {
				worksheet.getRow(index).eachCell({includeEmpty: false}, function (cell, cellNumber) { // subtotal lines
					cell.font = {bold: true};
				});
			});

			worksheet.getRow(2).eachCell({includeEmpty: false}, function (cell, cellNumber) { // Total
				cell.font = {bold: true, color: {argb: 'FFFFFF'}};
				cell.fill = totalFill;
			});

			// BOTTOM LINE
			worksheet.addRow([]);
			worksheet.addRow(['CloudBudget 2.0']);
			worksheet.addRow([new Date().toJSON().slice(0, 10).replace(/-/g, '/')]);
		}

		const maxNumber = cmp.get("v.report.cb4__MaxRowNumber__c");
		cmp.set("v.report.cb4__MaxRowNumber__c", 1000000);

		//EXCELL
		workbook.xlsx.writeBuffer().then(buffer => saveAs(new Blob([buffer]), cmp.get('v.report.Name') + '.xlsx')).catch(err => alert('Error writing excel export', err));
		cmp.set("v.report.cb4__MaxRowNumber__c", maxNumber);
		_hideSpinner(cmp);
	},
	downloadPDF: function (cmp, event, helper) {
		helper.helpDownloadPDF(cmp);
		helper.helpShowPDFPanel(cmp);
	},
	goToConfig: function (cmp, event, helper) {
		_CBRedirect.toComponent('cb4:ReportConfigurator', {'recordId': cmp.get("v.report.Id")});
	},

	displayColumnsSet: function (cmp, event, helper) {
		$A.util.removeClass(cmp.find("columnsSet"), "slds-hide");
	},
	applyColumnsFilter: function (cmp, event, helper) {
		_cl(JSON.stringify(cmp.get("v.displayedColumns")), 'pink');
		helper.helpRefreshReportDataAfterSpinner(cmp);
		$A.util.addClass(cmp.find("columnsSet"), "slds-hide");
	},
	closeColumnsFilter: function (cmp, event, helper) {
		$A.util.addClass(cmp.find("columnsSet"), "slds-hide");
		$A.util.addClass(cmp.find("bdgSet"), "slds-hide");
	},
	showDrillDown: function (cmp, event, helper) {
		let t = event.target.id;
		helper.helpGetDrillDown(cmp, t);
	},

	applyDT: function (cmp, event, helper) {
		_showSpinner(cmp);
		cmp.set("v.fitPageEnabled", true);
		helper.applyJQueryDataTable(cmp);
	},


});