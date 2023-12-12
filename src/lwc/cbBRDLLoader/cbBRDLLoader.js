/**
Copyright (c) 10 2022, CloudBudget, Inc.
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
import {api, LightningElement, track} from 'lwc';
import getBaseAnalyticsServer from '@salesforce/apex/CBReportingDepartmentLinePageController.getBaseAnalyticsServer';
import getAllBRDLServer from '@salesforce/apex/CBReportingDepartmentLinePageController.getAllBRDLServer';
import saveBRDLinesServer from '@salesforce/apex/CBReportingDepartmentLinePageController.saveBRDLinesServer';
import {_applyDecStyle, _message, _parseServerError, _setCell} from "c/cbUtils";
import {loadScript} from 'lightning/platformResourceLoader';
import exceljs from '@salesforce/resourceUrl/cb4__exceljs';

export default class cbBRDLLoader extends LightningElement {

	@api recordId;
	@track showSpinner = false;
	@track showUploadButton = true;
	@track BRDLines = [];
	@track logs = [];
	@track showSaveButton = false;
	@track disableSaveButton = false;
	@track serviceMap ={brd : 0, dim1 : 0, dim2 : 0, dim3 : 0};

	file;
	@track analytics;

	connectedCallback() {
		_applyDecStyle();
		this.getBaseAnalytics().then(() => null);
	};

	renderedCallback() {
		Promise.all([
			loadScript(this, exceljs),
		]).catch(function (e) {
			_message(`error`, `File load library error ${e}`);
		});
	}

	getBaseAnalytics = async () => {
		await getBaseAnalyticsServer()
			.then(analytics => this.analytics = analytics)
			.catch(e => _parseServerError('Get Base Analytics Error : ', e))
	};

	/////// DOWNLOAD FILE ////////////////////////
	async downloadBRDLinesFile() {
		this.showSpinner = true;
		this.showSaveButton = false;
		try {
			this.showSpinner = true;
			const fileName = 'Budget Reporting Department Lines';
			let workbook = new ExcelJS.Workbook();
			let BRDLSheet = workbook.addWorksheet('BRD Lines', {views: [{state: 'frozen', ySplit: 1, xSplit: 0}]});
			let serviceSheet = workbook.addWorksheet('Service', {views: [{state: 'frozen', ySplit: 1, xSplit: 0}]});

			await this.getBRDLines();
			this.createServiceSheet(serviceSheet);
			this.createBRDLinesSheet(BRDLSheet);

			let data = await workbook.xlsx.writeBuffer();
			const blob = new Blob([data], {type: 'application/octet-stream'});
			let downloadLink = document.createElement("a");
			downloadLink.href = window.URL.createObjectURL(blob);
			downloadLink.target = '_blank';
			downloadLink.download = fileName + '.xlsx';
			downloadLink.click();
			this.showSpinner = false;
		} catch (e) {
			_message('error', 'Download File Error : ' + e);
			this.showSpinner = false;
		}
	};

	getBRDLines = async () => {
		try {
			await getAllBRDLServer()
				.then(BRDLines => this.BRDLines = BRDLines)
				.catch(e => _parseServerError('Get list of BRDLines Error', e));
		} catch (e) {
			_message('error', 'Get BRDLines Error : ' + e);
		}
	};

	createBRDLinesSheet = (BRDLSheet) => {
		[10, 10, 45, 45, 45, 45].forEach((width, idx) => BRDLSheet.getColumn(idx + 1).width = width);
		const HEADER_FONT = {'bold': true, 'size': 10, 'name': 'Calibri', 'family': 2, 'scheme': 'minor'};
		const headerRow = BRDLSheet.getRow(1);
		this.headerTitles.forEach((t, idx) => {
			const cell = headerRow.getCell(idx + 1);
			_setCell(cell, t.l, null, HEADER_FONT); //_setCell = (cell, value, fill, font, numFmt, alignment, border)
		});
		const srvMap = this.serviceMap;
		this.BRDLines.forEach((brdl, idx) => {
			const row = BRDLSheet.getRow(idx + 2);
			const nameCell = row.getCell(1);
			const lvlCell = row.getCell(2);
			const brdCell = row.getCell(3);
			const dim1Cell = row.getCell(4);
			const dim2Cell = row.getCell(5);
			const dim3Cell = row.getCell(6);
			const sDateCell = row.getCell(7);
			const eDateCell = row.getCell(8);
			_setCell(nameCell, brdl.Name);
			if (brdl.Reporting_Department_Level__c) _setCell(lvlCell, brdl.Reporting_Department_Level__c);
			if (brdl.Budget_Reporting_Department__r) _setCell(brdCell, brdl.Budget_Reporting_Department__r.Name);
			if (brdl.Dimension_1__r) _setCell(dim1Cell, brdl.Dimension_1__r.Name);
			if (brdl.Dimension_2__r) _setCell(dim2Cell, brdl.Dimension_2__r.Name);
			if (brdl.Dimension_3__r) _setCell(dim3Cell, brdl.Dimension_3__r.Name);
			if (brdl.StartDate__c)   _setCell(sDateCell, brdl.StartDate__c);
			if (brdl.ExpDate__c)     _setCell(eDateCell, brdl.ExpDate__c);
			brdCell.dataValidation = {
				type: 'list',
				allowBlank: true,
				formulae: ['=Service!$A$2:$A$' + srvMap.brd]
			};
			dim1Cell.dataValidation = {
				type: 'list',
				allowBlank: true,
				formulae: ['=Service!$B$2:$B$' + srvMap.dim1]
			};
			dim2Cell.dataValidation = {
				type: 'list',
				allowBlank: true,
				formulae: ['=Service!$C$2:$C$' + srvMap.dim2]
			};
			dim3Cell.dataValidation = {
				type: 'list',
				allowBlank: true,
				formulae: ['=Service!$D$2:$D$' + srvMap.dim3]
			};
		});
	};

	createServiceSheet = (serviceSheet) => {
		let srvMap = this.serviceMap;
		const headerRow = serviceSheet.getRow(1);
		['Budget Reporting Department', 'Dimension 1', 'Dimension 2', 'Dimension 3'].forEach((t, idx) => headerRow.getCell(idx + 1).value = t);
		const populateAnalytics = (type, colIndex) => {
			if (this.analytics[type]) this.analytics[type].forEach( function(brd, idx) {
				srvMap[type] = idx + 2;
				serviceSheet.getRow(idx + 2).getCell(colIndex).value = brd.Name;
			}
		)};
		['brd', 'dim1', 'dim2', 'dim3'].forEach((type, idx) => populateAnalytics(type, idx + 1));
		this.serviceMap = srvMap;
	};

	headerTitles = [
		{l: 'Name', w: 10},
		{l: 'Lvl', w: 10},
		{l: 'Budget Reporting Department', w: 30},
		{l: 'Dimension 1', w: 30},
		{l: 'Dimension 2', w: 30},
		{l: 'Dimension 3', w: 30},
		{l: 'Start Date', w: 30},
		{l: 'Exp. Date', w: 30}
	];
	/////// DOWNLOAD FILE ////////////////////////


	/////// UPLOAD FILE //////////////////////////
	/**
	 * Method gets a file
	 */
	handleFilesUploading = (event) => {
		let file = event.target.files[0];
		let blob = new Blob([file, {type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'}]);
		let fileReader = new FileReader();
		this.showSpinner = true;
		fileReader.onload = async event => {
			try {
				let workbook = new ExcelJS.Workbook();
				await workbook.xlsx.load(event.target.result);
				this.disableSaveButton = false;
				await this.readBRDLines(workbook);
				this.showSaveButton = true;
				this.showSpinner = false;
			} catch (e) {
				_message('error', 'Parse File Error ' + e);
				this.showSpinner = false;
			}
		};
		fileReader.readAsArrayBuffer(blob);
	};

	readBRDLines = async (workbook) => {
		this.logs = [];
		this.BRDLines = [];
		const BRDLSheet = workbook.getWorksheet('BRD Lines');
		const dataMap = this.getMapsForFileReading();
		const colNumber = BRDLSheet.rowCount;

		function isValidDate(dateString) {
			var regEx = /^\d{4}-\d{2}-\d{2}$/;
			if(!dateString.match(regEx)) return false;  // Invalid format
			var d = new Date(dateString);
			var dNum = d.getTime();
			if(!dNum && dNum !== 0) return false; // NaN value, Invalid date
			return d.toISOString().slice(0,10) === dateString;
		}

		for (let i = 2; i <= colNumber; i++) {
			const row = BRDLSheet.getRow(i);
			const BRDL = {Description__c: 'Test'};
			const brdLvlName = row.getCell(2).value;
			const brdName = row.getCell(3).value;
			const dim1Name = row.getCell(4).value;
			const dim2Name = row.getCell(5).value;
			const dim3Name = row.getCell(6).value;
			const sDate = row.getCell(7).value;
			const eDate = row.getCell(8).value;
			if (brdName && brdName.length > 1) {
				const brdId = dataMap.brd[brdName];
				if (!brdId) {
					this.logs.unshift({
						message: `ERROR : LINE ${i + 1} : Budget Reporting Department "${brdName}" is not in the system`,
						cl: 'error'
					});
					this.disableSaveButton = true;
				}
				BRDL.Budget_Reporting_Department__c = brdId;
				BRDL.key = `${brdLvlName} / ${brdName}`;
			}
			if (dim1Name && dim1Name.length > 1) {
				const dim1Id = dataMap.dim1[dim1Name];
				if (!dim1Id) {
					this.logs.unshift({
						message: `ERROR : LINE ${i + 1} : Dimension 1 "${dim1Name}" is not in the system`,
						cl: 'error'
					});
					this.disableSaveButton = true;
				}
				BRDL.Dimension_1__c = dim1Id;
				BRDL.key += ' / ' + dim1Name;
			}
			if (dim2Name && dim2Name.length > 1) {
				const dim2Id = dataMap.dim2[dim2Name];
				if (!dim2Id) {
					this.logs.unshift({
						message: `ERROR : LINE ${i + 1} : Dimension 2 "${dim2Name}" is not in the system`,
						cl: 'error'
					});
					this.disableSaveButton = true;
				}
				BRDL.Dimension_2__c = dim2Id;
				BRDL.key += ' / ' + dim2Name;
			}
			if (dim3Name && dim3Name.length > 1) {
				const dim3Id = dataMap.dim3[dim3Name];
				if (!dim3Id) {
					this.logs.unshift({
						message: `ERROR : LINE ${i + 1} : Dimension 3 "${dim3Name}" is not in the system`,
						cl: 'error'
					});
					this.disableSaveButton = true;
				}
				BRDL.Dimension_3__c = dim3Id;
				BRDL.key += ' / ' + dim3Name;
			}
			if((sDate && sDate.length > 1)  || sDate instanceof Date){
				if(sDate instanceof Date){
					let year = sDate.toLocaleString("default", { year: "numeric" });
					let month = sDate.toLocaleString("default", { month: "2-digit" });
					let day = sDate.toLocaleString("default", { day: "2-digit" });
					let formattedDate = year + "-" + month + "-" + day;
					BRDL.StartDate__c = formattedDate;
				}else if(isValidDate(sDate)) BRDL.StartDate__c = sDate;
				else {
					let csDate = sDate.split("/").reverse().join("-");
					if(isValidDate(csDate)) BRDL.StartDate__c = csDate;
					else {
						this.logs.unshift({
							message: `ERROR : LINE ${i + 1} : Start Date "${sDate}" not in correct format, use "YYYY-mm-dd" format, example: "2023-17-11"`,
							cl: 'error'
						});
						this.disableSaveButton = true;
					}
				}
			}
			if((eDate && eDate.length > 1) || eDate instanceof Date){
				if(eDate instanceof Date){
					let year = eDate.toLocaleString("default", { year: "numeric" });
					let month = eDate.toLocaleString("default", { month: "2-digit" });
					let day = eDate.toLocaleString("default", { day: "2-digit" });
					let formattedDate = year + "-" + month + "-" + day;
					BRDL.ExpDate__c = formattedDate;
				}else if(isValidDate(eDate)){
					BRDL.ExpDate__c = eDate;
				}else{
					let ceDate = eDate.split("/").reverse().join("-");
					if(isValidDate(ceDate)) BRDL.ExpDate__c = ceDate;
					else{
						this.logs.unshift({
							message: `ERROR : LINE ${i + 1} : Exp. Date "${eDate}" not in correct format, use "YYYY-mm-dd" format, example "2023-17-11"`,
							cl: 'error'
						});
						this.disableSaveButton = true;
					}
				}
			}
			this.BRDLines.push(BRDL);
		}
		const uniqueBRDLKeys = {};
		this.BRDLines.forEach((brd, i) => {
			const theSameBRDL = uniqueBRDLKeys[brd.key];
			if (theSameBRDL) this.logs.push({
				message: `Line ${i + 2}. The combination "${brd.key}" appears more than once`,
				cl: 'warning'
			});
			uniqueBRDLKeys[brd.key] = true;
		});
		if(this.BRDLines.length === 0){
			this.logs.unshift({
				message: `ERROR : Excel file is empty.`,
				cl: 'error'
			});
			this.disableSaveButton = true;
		}
		this.BRDLines.forEach(brd => console.log(JSON.stringify(brd)));
		console.log('Number of lines: ' + this.BRDLines.length);
	};

	getMapsForFileReading = () => {
		const dataMap = {brd: {}, dim1: {}, dim2: {}, dim3: {}};
		this.analytics.brd.forEach(d => dataMap.brd[d.Name] = d.Id);
		this.analytics.dim1.forEach(d => dataMap.dim1[d.Name] = d.Id);
		this.analytics.dim2.forEach(d => dataMap.dim2[d.Name] = d.Id);
		this.analytics.dim3.forEach(d => dataMap.dim3[d.Name] = d.Id);
		return dataMap;
	};

	saveBRDLines = () => {
		if(confirm("All the previous BRD lines will be deleted, and the new ones will be created. To continue, click the \"Ok\" button.")){
			this.showSpinner = true;
			saveBRDLinesServer({BRDLines: this.BRDLines, safeMode: false})
				.then(() => {
					_message('success', 'Saved');
					this.showSpinner = false;
				})
				.catch(e => _parseServerError('Saving Error : ', e));
		}
	};

	saveBRDLinesSafe = () => {
		if(confirm("All the existing BRD lines will be maintained, and the new ones will be created. To continue, click the \"Ok\" button.")){
			this.showSpinner = true;
			saveBRDLinesServer({BRDLines: this.BRDLines, safeMode: true})
				.then(() => {
					_message('success', 'Saved');
					this.showSpinner = false;
				})
				.catch(e => _parseServerError('Saving Error : ', e));
		}
	};
	/////// UPLOAD FILE //////////////////////////
}