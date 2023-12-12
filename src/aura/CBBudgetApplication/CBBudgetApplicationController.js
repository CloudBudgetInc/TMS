({
	doInit: function (cmp, event, helper) {
		helper.helpGetGrantsList(cmp);
		_getCurrentUserSettings(cmp);
		document.title = _TEXT.APPS.MODULE_HEADER;
		_showSpinner(cmp);

		window.setTimeout(
			$A.getCallback(function () {
				try {
					const recordId = cmp.get("v.recordId");
					if (recordId != null) {
						cmp.set("v.mode", 'single');
						cmp.set("v.app.Id", recordId);
						cmp.set("v.recordId", null);
					}

					let mode = cmp.get("v.mode");

					helper.helpGetBudgetAppDimension(cmp);
					helper.helpGetBudgetAppAmountDimension(cmp);
					if (mode === 'table') {
						helper.helpSetTableHeight(cmp);
						cmp.set("v.headerTitle", _TEXT.APPS.MODULE_HEADER);
						helper.helpGetNeededSO(cmp);
						helper.helpGetMainAppSO(cmp);
						helper.helpGetAppList(cmp);
					} else {
						helper.helpRefreshSingleApp(cmp);
					}
				} catch (e) {
					alert('Init wizard error: ' + e);
				}
			}), 10
		);

		$(window).scroll(function () {
			let the_top = $(document).scrollTop();
			let inpMode = cmp.get("v.inputMode");
			if (the_top > 1000 && (!inpMode)) {
				$('#nav').addClass('fixed');
			} else {
				$('#nav').removeClass('fixed');
			}
		});

	},

	saveApp: function (cmp, event, helper) {
		helper.helpSaveApp(cmp);
	},
	createApp: function (cmp, event, helper) {
		helper.helpCreateApp(cmp);
	},
	cloneApp: function (cmp, event, helper) {
		helper.helpCloneApp(cmp);
	},
	applyTitleRule: function (cmp, event, helper) {
		helper.helpApplyTitleRule(cmp);
	},
	deleteApp: function (cmp, event, helper) {
		helper.helpDeleteApp(cmp);
	},
	updateApp: function (cmp, event, helper) {
		_showSpinner(cmp);
		helper.helpGetAppList(cmp);
	},
	recalculateAllApps: function (cmp, event, helper) {
		_showSpinner(cmp);
		//helper.helpUpdateApps(cmp);
		//helper.helpGetAppList(cmp);
		helper.helpRecalculateTotals(cmp);
	},

	valueChangeResponse: function (cmp, event, helper) {
		cmp.set("v.needSave", true);
		const row = event.getSource().get('v.name');
		const type = event.getSource().get('v.label');
		helper.helpCalculateRow(cmp, row, type);
		helper.helpCalulateGrantTotals(cmp, type);
		helper.helpCalculateTotalRows(cmp, type);
		helper.helpCalculateMarginRow(cmp);
	},

	focusHandler: function (cmp, event, helper) {
		//const accesskey = event.getSource().get('v.name');
		alert('Soon there will be the cell comment');
	},

	addLine: function (cmp, event, helper) {
		const type = event.getSource().get('v.name');
		helper.helpAddLine(cmp, type, undefined, false);
	},

	calculateDialogTotals: function (cmp, event, helper) {
		helper.helpCalculateDialogTotals(cmp);
	},

	checkIfNeedSave: function (cmp, event, helper) {
		if (cmp.get('v.needSave')) alert('Please save the application before apply')
	},

	handleRowAction: function (cmp, event, helper) {
		helper.helpHandleTableButtons(cmp, event);
	},

	applyCalcRuleStep1: function (cmp, event, helper) {
		helper.helpApplyCalcRules(cmp, 1);
	},
	applyCalcRuleStep2: function (cmp, event, helper) {
		helper.helpApplyCalcRules(cmp, 2);
	},
	applyCalcRuleStep3: function (cmp, event, helper) {
		helper.helpApplyCalcRules(cmp, 3);
	},

	redirectToParent: function (cmp, event, helper) {
		_CBRedirect.toSObject(cmp.get("v.app.cb4__Tag1__c"));
	},
	redirectToApp: function (cmp, event, helper) {
		_CBRedirect.toSObject(event.getSource().get('v.value'));
	},

	redirectToAppSheet: function (cmp, event, helper) {
		helper.helpRedirectToAppSheet(cmp);
	},
	/**
	 * Simple line title was clicked
	 */
	showDetails: function (cmp, event, helper) {
		let rowShrinkId = event.getSource().get('v.value');
		if(rowShrinkId !== '') helper.helpShowDetails(cmp, rowShrinkId);
	},

	showGeneratorSettings: function (cmp, event, helper) {
		helper.helpShowGeneratorSettings(cmp);
	},
	setPrice: function (cmp, event, helper) {
		helper.helpSetPrice(cmp);
		helper.helpUpdateAppLineTitle(cmp, event.getSource().get("v.accesskey"));
	},
	setRate: function (cmp, event, helper) {
		helper.helpSetRate(cmp);
		helper.helpUpdateAppLineTitle(cmp, event.getSource().get("v.accesskey"));
	},
	applyDetails: function (cmp, event, helper) {
		helper.helpApplyDetails(cmp);
	},
	applyDetailsAndClone: function (cmp, event, helper) {
		let curRow = JSON.parse(JSON.stringify(cmp.get("v.row")));
		helper.helpApplyDetails(cmp);
		cmp.set('v.row', curRow);
		curRow.rowValues.forEach(r=>{r.v = 0; r.q = 0; r.p = 0;});
		helper.helpAddLine(cmp, curRow.ie, curRow, true);
	},
	applyDetailsAndNew: function (cmp, event, helper) {
		let curRow = JSON.parse(JSON.stringify(cmp.get("v.row")));
		helper.helpApplyDetails(cmp);
		curRow.description = '';
		for(let i = 5; i <= 10; i++) curRow['dim' + i] = '';
		for(let i = 6; i <= 9; i++) curRow['text' + i] = '';
		for(let i = 6; i <= 10; i++) curRow['decimal' + i] = '';
		cmp.set('v.row', curRow);
		curRow.rowValues.forEach(r=>{r.v = 0; r.q = 0; r.p = 0;});
		helper.helpAddLine(cmp, curRow.ie, curRow, false);
	},
	closeDetails: function (cmp, event, helper) {
		helper.helpCloseDetails(cmp);
	},
	shrinkDetails: function (cmp, event, helper) {
		let rowShrinkId = event.getSource().get('v.value');
		helper.helpShrinkDetails(cmp, rowShrinkId);
	},
	turnDetailMode: function (cmp, event, helper) {
		_showSpinner(cmp);
		setTimeout(function () {
			const on = event.getSource().get('v.checked'); // TODO Toggle value!
			if (on) {
				cmp.set("v.showMode", true);
			} else {
				cmp.set("v.showMode", false);
			}
			_hideSpinner(cmp);
		}, 10);
	},
	deleteRow: function (cmp, event, helper) {
		let rowId = event.getSource().get('v.value');
		if(rowId !== '') {
			if (!confirm(_TEXT.APPS.DELETE_ROW_CONFIRM)) return;
			helper.helpDeleteRow(cmp, rowId);
		}
	},

	/**
	 * The method converts calculation rule line to simple line
	 */
	convertToSimpleRow: function (cmp, event, helper) {
		let rowId = event.getSource().get('v.value');
		helper.helpConvertToSimpleRow(cmp, rowId);
		helper.helpCloseDetails(cmp);
	},
	updateAppLineTitle: function (cmp, event, helper) {
		cmp.set("v.needSave", true);
		helper.helpUpdateAppLineTitle(cmp, event.getSource().get("v.accesskey"));
	},
	applySinglePageFilter: function (cmp, event, helper) {
		helper.helpApplyPageFilters(cmp);
	},
	backToMainTable: function (cmp, event, helper) {
		helper.helpBackToMainTable(cmp);
	},
	generateAppLines: function (cmp, event, helper) {
		_showSpinner(cmp);
		window.setTimeout(
			$A.getCallback(function () {
				helper.helpGenerateListOfEmptyLines(cmp);
			}), 7
		);

	},

	handleChatEvent: function (cmp, event, helper) {
		let message = event.getParam("param");
		helper.helpSaveChat(cmp, message);
	},

	handleFileEvent: function (cmp, event, helper) {

		let content = event.getParam("file");

		function _base64ToArrayBuffer(base64) {
			let binary_string = window.atob(base64);
			let len = binary_string.length;
			let bytes = new Uint8Array(len);
			for (var i = 0; i < len; i++) {
				bytes[i] = binary_string.charCodeAt(i);
			}
			return bytes.buffer;
		}

		try {
			//saveAs(new Blob([_base64ToArrayBuffer(content)]), 'Content.xlsx');
		} catch (e) {
			alert('Content: ' + e);
		}
		try {
			let workbook = new ExcelJS.Workbook();
			let blob = new Blob([_base64ToArrayBuffer(content)]);
			let fileReader = new FileReader();
			fileReader.onload = function (event) {
				workbook.xlsx.load(event.target.result).then(function () {
					setTimeout(function () {
						helper.helpApplyExcelFile(cmp, workbook);
					}, 1000);
				}).catch(err => _cl('Error writing excel import' + err, 'red'));
			};
			fileReader.readAsArrayBuffer(blob);

		} catch (e) {
			alert(e);
		}
	},

	/** EXCEL */
	showExcelPanel: function (cmp, event, helper) {
		helper.helpShowExcelPanel(cmp);
	},
	downloadExcel: function (cmp, event, helper) {
		helper.helpDownloadExcel(cmp, 'ExcelFile');
		helper.helpShowExcelPanel(cmp);
	},
	downloadExcelGD: function (cmp, event, helper) {
		helper.helpDownloadExcel(cmp, 'GoogleDisk');
	},

	showHideGD: function (cmp, event, helper) {
		if (cmp.get('v.showGoogleDrive')) {
			cmp.set('v.showGoogleDrive', false)
		} else {
			cmp.set('v.showGoogleDrive', true)
		}
	},

	handleFilesChange: function (cmp, event, helper) {
		_showSpinner(cmp);
		helper.helpShowExcelPanel(cmp);
		let file = event.getSource().get("v.files")[0];

		let workbook = new ExcelJS.Workbook();
		let blob = new Blob([file, {type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'}]);

		let fileReader = new FileReader();
		fileReader.onload = function (event) {
			workbook.xlsx.load(event.target.result).then(function () {
				setTimeout(function () {
					helper.helpApplyExcelFile(cmp, workbook);
				}, 100);
			}).catch(err => _cl('Error writing excel import' + err, 'red'));

		};
		fileReader.readAsArrayBuffer(blob);
	},
	/** EXCEL */
	/** PDF */
	showPDFPanel: function (cmp, event, helper) {
		helper.helpShowPDFPanel();
	},
	/** PDF */


	showPopover: function (cmp, event, helper) {
		let key = event.getSource().get('v.value');
		cmp.set("v.popKey", key);
		const objects = helper.helpGetRowInfo(cmp, key);

		$A.createComponent('c:PopoverInfo',
			{
				"objects": objects
			},
			function (popoverInfo, status, errorMessage) {
				//Add the new button to the body array
				if (status === "SUCCESS") {
					let newCmp = [];
					newCmp.push(popoverInfo);
					cmp.set("v.someCmp", newCmp);
					$A.enqueueAction(cmp.get('c.showPopover2'));
				} else if (status === "INCOMPLETE") {

				} else if (status === "ERROR") {
					_CBMessages.fireErrorMessage("Drill Down Component failed to load: " + e);
				}
			}
		);
	},

	applyPopulation: function (cmp, event, helper) {
		let process = event.getParam("value");
		helper.helpApplyPopulation(cmp, process);
	},

	showPopover2: function (cmp, event, helper) {
		let key = cmp.get("v.popKey");
		key = '.' + key + 'pop';
		let compo = cmp.get("v.someCmp");
		cmp.find('overlayLib').showCustomPopover({
			body: compo,
			header: "Header Title",
			referenceSelector: key,
			cssClass: "slds-nubbin_left,slds-popover,no-pointer,cBudgetApplication,popoverclass"
		}).then(function (overlay) {
			setTimeout(function () {
				overlay.close();
			}, 3000);
		});
	},

	filterProducts: function (cmp, evt, helper) {
		if (evt.keyCode === 13) { // Enter pressed
			let queryTerm = cmp.find('enter-search').get('v.value');
			helper.helpFilterProducts(cmp, queryTerm);
		}
	},

	refreshCalcRules: function (cmp, evt, helper) {
		helper.helpRefreshCalcRules(cmp);

	},

	// BACKUP //
	refreshBackupList: function (cmp, event, helper) {
		helper.helpGetBackupList(cmp);
	},
	showBackup: function (cmp, event, helper) {
		$A.util.removeClass(cmp.find("backupDiv"), "slds-hide");
		$A.util.removeClass(cmp.find("modalBackGround"), "slds-hide");
		helper.helpGetBackupList(cmp);
	},
	applyBackup: function (cmp, event, helper) {
		let backupId = event.getSource().get('v.value');
		helper.helpApplyBackup(cmp, backupId);
		$A.util.addClass(cmp.find("backupDiv"), "slds-hide");
		$A.util.addClass(cmp.find("modalBackGround"), "slds-hide");
	},
	hideBackup: function (cmp, event, helper) {
		cmp.set("v.backupList", []);
		$A.util.addClass(cmp.find("backupDiv"), "slds-hide");
		$A.util.addClass(cmp.find("modalBackGround"), "slds-hide");
	},
	// BACKUP //

	/**
	 * This method will be invoked from the additional Budget App Component
	 */
	applyAdditionalComponent: function (cmp, event, helper) {
		let childCMP = cmp.get("v.additionalCMP");
		if(childCMP!== undefined && cmp.get('v.additionalComponent').length > 0) {
			cmp.set("v.app", childCMP.get("v.app"));
			cmp.set("v.template", childCMP.get("v.template"));
			cmp.set("v.row", childCMP.get("v.row"));
		}

		if(cmp.get('v.additionalBudgetLineComponent') !== undefined && cmp.get('v.additionalBudgetLineComponent').length > 0) {
			function setParentParams() {
				let param = event.getParam('row');
				if (!_isInvalid(param)) {
					cmp.set('v.row', param);
				}
			}

			window.setTimeout(
				$A.getCallback(function () {
					setParentParams();
				}), 10
			);
		}
	},

	sendIncomeData: function(cmp, evt, h) {
		let addComponents = cmp.get('v.additionalComponent');
		if(addComponents !== undefined && addComponents.length > 0){
			let childCMP = cmp.get("v.additionalComponent")[0];
			if(childCMP !== undefined) {
				try {
					childCMP.setData(null, cmp.get('v.incomeData'));
				}catch (e){}
			}
		}
	},

	sendIncomeDownUpSubData: function(cmp, evt, h) {
		let addComponents = cmp.get('v.additionalComponent');
		if(addComponents !== undefined && addComponents.length > 0){
			let childCMP = cmp.get("v.additionalComponent")[0];
			if(childCMP !== undefined) {
				try {
					childCMP.setData(cmp.get('v.incomeDownUpSubData'));
				}catch (e){}
			}
		}
	},

	sendIncomeTopDownSubData: function(cmp, evt, h) {
		let addComponents = cmp.get('v.additionalComponent');
		if(addComponents !== undefined && addComponents.length > 0){
			let childCMP = cmp.get("v.additionalComponent")[0];
			if(childCMP !== undefined) {
				try {
					childCMP.setData(cmp.get('v.incomeTopDownSubData'));
				}catch (e){}
			}
		}
	},

	sendExpenseData: function(cmp, evt, h) {
		let addComponents = cmp.get('v.additionalComponent');
		if(addComponents !== undefined && addComponents.length > 0){
			let childCMP = cmp.get("v.additionalComponent")[0];
			if(childCMP !== undefined) {
				try {
					childCMP.setData(null, cmp.get('v.expenseData'));
				}catch (e){}
			}
		}
	},

	sendExpenseDownUpSubData: function(cmp, evt, h) {
		let addComponents = cmp.get('v.additionalComponent');
		if(addComponents !== undefined && addComponents.length > 0){
			let childCMP = cmp.get("v.additionalComponent")[0];
			if(childCMP !== undefined) {
				try {
					childCMP.setData(cmp.get('v.expenseDownUpSubData'));
				}catch (e){}
			}
		}
	},

	sendExpenseTopDownSubData: function(cmp, evt, h) {
		let addComponents = cmp.get('v.additionalComponent');
		if(addComponents !== undefined && addComponents.length > 0){
			let childCMP = cmp.get("v.additionalComponent")[0];
			if(childCMP !== undefined) {
				try {
					childCMP.setData(cmp.get('v.expenseTopDownSubData'));
				}catch (e){}
			}
		}
	},

	sendTotalData: function(cmp, evt, h) {
		let addComponents = cmp.get('v.additionalComponent');
		if(addComponents !== undefined && addComponents.length > 0){
			let childCMP = cmp.get("v.additionalComponent")[0];
			if(childCMP !== undefined) {
				try {
					childCMP.setData(cmp.get('v.totalData'));
				}catch (e){}
			}
		}
	},

	sendTargetTotalData: function(cmp, evt, h) {
		let addComponents = cmp.get('v.additionalComponent');
		if(addComponents !== undefined && addComponents.length > 0){
			let childCMP = cmp.get("v.additionalComponent")[0];
			if(childCMP !== undefined) {
				try {
					childCMP.setData(cmp.get('v.targetTotalData'));
				}catch (e){}
			}
		}
	},

	sendRowDataToBLComponent: function(cmp, evt, h) {
		let addComponents = cmp.get('v.additionalBudgetLineComponent');
		if(addComponents !== undefined && addComponents.length > 0){
			let childCMP = cmp.get("v.additionalBudgetLineComponent")[0];
			if(childCMP !== undefined) {
				try {
					childCMP.setData(cmp.get('v.row'));
				}catch (e){}
			}
		}
	},

	onHideLevelChanges: function (cmp, event, helper) {
		_showSpinner(cmp);
		window.setTimeout(
			$A.getCallback(function () {
				helper.helpFoldUnfoldList(cmp);
			}), 10
		);
	},

	hideNotification: function (cmp, evt, h){
		$A.util.addClass(cmp.find("cbnotification"), "slds-hide");
		if(evt.getSource().get("v.value") === true) window.localStorage.setItem('resolutionNotify', 'false');
		else window.localStorage.setItem('resolutionNotify', 'true');
	},

	handleUploadFinished: function (cmp, evt, h){
		h.getAttachedDocuments(cmp);
	},

	handleChildEvent: function (cmp, event, helper) {
		event.getParam("param");
	},
});