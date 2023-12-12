({
    doInit: function (cmp, event, helper) {
        helper.helpGetReport(cmp);
        helper.helpGetTableHeaders(cmp);
        helper.helpGetReportColumnsServer(cmp);
        helper.helpGetDisplayGroups(cmp);
        //helper.helpGetCBalances(cmp);//  _this.helpGenerateReportLines(cmp); _this.helpGetFilterSelectOptions(cmp); _this.helpRefreshReportData(cmp);
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

    downloadDim2ExcelReport: function(cmp, evt, h) {
        let report = cmp.get("v.report");
        const customFormat = report.cb4__Description__c === 'Custom Excel';
        let repDepartments = cmp.get('v.d1SO');
        cmp.set("v.d1filter", null);
        cmp.set("v.d2filter", null);
        cmp.set("v.d3filter", null);
        cmp.set("v.d4filter", null);
        cmp.set("v.d5filter", null);
        cmp.set("v.d6filter", null);
        cmp.set("v.d7filter", null);

        const getRowAmount = (val) => {
            if (val === '-' || val.includes('%')) return val;
            if (parseInt(val.replace(' %').replace(/,/g, '')) === 0) return '-';
            if (val.includes(' %')) parseFloat(val.replace(' %').replace(/,/g, '')) + ' %';
            return parseFloat(val.replace(/,/g, ''));
        };
        const setCell = (cell, value, fill, font, numFmt, alignment, border) => {
            cell.value = value;
            cell.fill = fill;
            cell.font = font;
            cell.numFmt = numFmt;
            cell.alignment = alignment;
            cell.border = border;
        };

        let workbook = new ExcelJS.Workbook();
        // refresh data from the source
        let origin = JSON.parse(JSON.stringify(cmp.get("v.rowsOriginal")));

        let columns = JSON.parse(JSON.stringify(cmp.get("v.reportColumnsOriginal")));
        cmp.set("v.reportColumns", columns);

        let header = JSON.parse(JSON.stringify(cmp.get("v.tableHeadersOriginal")));
        cmp.set("v.tableHeaders", header);
        let n = cmp.get("v.numberOfTextColumns"); // the number of text columns
        cmp.set("v.rows", origin);
        h.helpApplyDimensionFilter(cmp); // dimension filter
        h.helpCalculateColumnTotals(cmp); // vertical totals
        h.helpCalculateRowTotals(cmp); // horizontal total

        h.helpFormatNumbers(cmp); // formatting

        h.helpShowHideSimpleRows(cmp); // total rows only filter
        h.helpApplyColumnsFilter(cmp); // display only allowed columns filter
        /////// ADD SHEET TO EXCELL
        let tableRows = h.restructureLines(JSON.parse(JSON.stringify(cmp.get('v.rows'))));
        let sheetName = report.Name;

        let fixedColumns = report.cb4__FixedColumns__c;
        if (_isInvalid(fixedColumns)) fixedColumns = 1; else fixedColumns--;
        let tableHeaders = cmp.get("v.tableHeaders");
        let bdgI = cmp.get('v.bdgI');

        for (let i = 0; i < tableHeaders.length; i++) {
            if (tableHeaders[i] === "BDG") {
                bdgI = i;
                cmp.set('v.bdgI', bdgI);
            }
        }
        if (bdgI !== null){
            if(tableHeaders[bdgI] ==='BDG')	{
                tableHeaders.splice(bdgI, 1);
            }
            n--;
        }

        const incomeWorksheet = workbook.addWorksheet('Revenues', {
            views: [
                {state: 'frozen', ySplit: 6, xSplit: fixedColumns, showGridLines: false}
            ]
        });
        const expenseWorksheet = workbook.addWorksheet('Expenses', {
            views: [
                {state: 'frozen', ySplit: 6, xSplit: fixedColumns, showGridLines: false}
            ]
        });
        incomeWorksheet.getCell('A1').font = {
            name: 'Calibri',
            family: 4
        };
        expenseWorksheet.getCell('A1').font = {
            name: 'Calibri',
            family: 4
        };
        /** LINE OVER HEADER **/
        const overHeaderTitlesRow = incomeWorksheet.getRow(5); // header row position from top
        incomeWorksheet.mergeCells(5, 1, 5, 4); // merge by start row, start column, end row, end column (equivalent to A1:D1)
        incomeWorksheet.mergeCells(5, 5, 5, 9); // merge by start row, start column, end row, end column (equivalent to E5:K5)
        incomeWorksheet.mergeCells(5, 10, 5, 14); // merge by start row, start column, end row, end column (equivalent to L5:Q5)
        incomeWorksheet.mergeCells(5, 15, 5, 17); // merge by start row, start column, end row, end column (equivalent to R5:T5)
        setCell(overHeaderTitlesRow.getCell(5), 'Current Month', h.overHeaderHeaderFill, h.overHeaderHeaderFont, null, h.headerTitleAlign, h.borderTopBottom);
        setCell(overHeaderTitlesRow.getCell(10), 'YTD', h.overHeaderHeaderFill, h.overHeaderHeaderFont, null, h.headerTitleAlign, h.borderTopBottom);
        setCell(overHeaderTitlesRow.getCell(15), '12 Months', h.overHeaderHeaderFill, h.overHeaderHeaderFont, null, h.headerTitleAlign, h.borderTopBottom);

        const overHeaderTitlesRowExpenses = expenseWorksheet.getRow(5); // header row position from top
        expenseWorksheet.mergeCells(5, 1, 5, 4); // merge by start row, start column, end row, end column (equivalent to A1:D1)
        expenseWorksheet.mergeCells(5, 5, 5, 9); // merge by start row, start column, end row, end column (equivalent to E5:K5)
        expenseWorksheet.mergeCells(5, 10, 5, 14); // merge by start row, start column, end row, end column (equivalent to L5:Q5)
        expenseWorksheet.mergeCells(5, 15, 5, 17); // merge by start row, start column, end row, end column (equivalent to R5:T5)
        setCell(overHeaderTitlesRowExpenses.getCell(5), 'Current Month', h.overHeaderHeaderFill, h.overHeaderHeaderFont, null, h.headerTitleAlign, h.borderTopBottom);
        setCell(overHeaderTitlesRowExpenses.getCell(10), 'YTD', h.overHeaderHeaderFill, h.overHeaderHeaderFont, null, h.headerTitleAlign, h.borderTopBottom);
        setCell(overHeaderTitlesRowExpenses.getCell(15), '12 Months', h.overHeaderHeaderFill, h.overHeaderHeaderFont, null, h.headerTitleAlign, h.borderTopBottom);
        /** LINE OVER HEADER **/
        /** HEADERS  Reporting Dep	Type	Subtype ....**/
        const headerTitlesRow = incomeWorksheet.getRow(6); // header row position from top
        headerTitlesRow.height = 50;
        headerTitlesRow.values = tableHeaders; // header values like ['Reporting Dep', 'Type', 'Subtype' ....]
        headerTitlesRow.eachCell({includeEmpty: true}, (cell, i) => setCell(cell, i <= 3 ? '' : cell.value, h.headerFill, h.totalFont, null, h.headerTitleAlign, h.borderTopBottom)); // header styles

        const headerTitlesRowExpenses = expenseWorksheet.getRow(6); // header row position from top
        headerTitlesRowExpenses.height = 50;
        headerTitlesRowExpenses.values = tableHeaders; // header values like ['Reporting Dep', 'Type', 'Subtype' ....]
        headerTitlesRowExpenses.eachCell({includeEmpty: true}, (cell, i) => setCell(cell, i <= 3 ? '' : cell.value, h.headerFill, h.totalFont, null, h.headerTitleAlign, h.borderTopBottom)); // header styles
        /** HEADERS  Reporting Dep	Type	Subtype ....**/
            // ROWS
        const departmentName = {};
        const subtotalTypes = ['total', 'topHeader'];
        for (let idx = 1; idx <= 5; idx++) subtotalTypes.push(`subTotal${idx}`);
        let amountRowPosition = 7; // start position is 6
        let amountRowPositionExpenses = 7; // start position is 6
        let cellPosition;
        let subtotalFillMap = {
            subTotal1: h.overHeaderHeaderFill,
            subTotal2: h.overHeaderHeaderFill,
            subTotal3: h.subTotal3Fill,
            total: h.topHeaderFill,
            topHeader: h.topHeaderFill,
        };
        console.group('DEBUG');
        console.log('tableRows', JSON.parse(JSON.stringify(tableRows)));
        console.groupEnd();
        tableRows.forEach(row => {
            try {
                let excelRow = expenseWorksheet.getRow(amountRowPositionExpenses);
                if(row.l1Long === 'REVENUE' || row.l2 === 'Revenue'){
                    excelRow = incomeWorksheet.getRow(amountRowPosition); // one row
                    amountRowPosition++;
                }else{
                    amountRowPositionExpenses++;
                }
                cellPosition = 1;
                const rowIsSubTotal = subtotalTypes.includes(row.type);
                const subtotalFill = row.type ? subtotalFillMap[row.type] : undefined;
                const subtotalFont = row.type === 'subTotal1' || row.type === 'subTotal2' ? h.overHeaderHeaderFont : (row.type === 'total' ? h.totalFont : h.generalFont);

                departmentName[row[`l1Long`]] = true; // collection of department names
                if (row.type === 'topHeader') excelRow.height = 23;
                for (let j = 0; j < n; j++) {
                    const cell = excelRow.getCell(cellPosition++);
                    let value = row[`l${j + 1}Long`];
                    if (rowIsSubTotal) {
                        value = value === '-' ? null : value;
                        setCell(cell, value, subtotalFill, subtotalFont, null, h.rowTitleAlign, h.borderTopBottom);
                    } else {
                        setCell(cell, value, null, h.simpleFont);
                    }
                }// text part of a row

                row.v.forEach((val, idx) => {
                    const cell = excelRow.getCell(cellPosition++);
                    const value = row.type === 'topHeader' ? '' : getRowAmount(val);
                    if (rowIsSubTotal) {
                        if(row.type !== 'topHeader') setCell(cell, value, subtotalFill, subtotalFont, h.NUM_FORMAT, h.decAlign, h.borderTopBottom);
                        else setCell(cell, value, subtotalFill, subtotalFont, '@', h.decAlign, h.borderTopBottom);
                    } else {
                        setCell(cell, value, null, h.simpleFont, h.NUM_FORMAT, h.decAlign);
                    }
                });
            } catch (e) {
                alert('ERROR: ' + e);
            }
        });
        h.setColumnsWidth(incomeWorksheet);
        h.setColumnsWidth(expenseWorksheet);
        h.makeTransparentExtraExcelTitles(incomeWorksheet, tableRows, true);
        h.makeTransparentExtraExcelTitles(expenseWorksheet, tableRows, true);
        ['TOTAL', 'EXPENSE', 'REVENUE'].forEach(title => delete departmentName[title]);
        h.addReportHeaderLines(incomeWorksheet, customFormat, Object.keys(departmentName).join(', '), cmp.get('v.displayedColumns'));
        h.addReportHeaderLines(expenseWorksheet, customFormat, Object.keys(departmentName).join(', '), cmp.get('v.displayedColumns'));
        h.addVerticalBorders(incomeWorksheet, tableRows.length);
        h.addVerticalBorders(expenseWorksheet, tableRows.length);
        incomeWorksheet.autoFilter = 'A5:D5';
        expenseWorksheet.autoFilter = 'A5:D5';

        workbook.xlsx.writeBuffer().then(buffer => saveAs(new Blob([buffer]), report.Name + '.xlsx')).catch(err => alert('Error writing excel export', err));
        _hideSpinner(cmp);
    },

    downloadExcelForSelectedBDGs: function(cmp, evt, h) {
        const bdgs = cmp.get('v.selectedBDGs');
        let report = cmp.get("v.report");
        const customFormat = report.cb4__Description__c === 'Custom Excel';
        cmp.set("v.d1filter", null);
        cmp.set("v.d3filter", null);
        cmp.set("v.d4filter", null);
        cmp.set("v.d5filter", null);
        cmp.set("v.d6filter", null);
        cmp.set("v.d7filter", null);

        const getRowAmount = (val) => {
            if (val === '-' || val.includes('%')) return val;
            if (parseInt(val.replace(' %').replace(/,/g, '')) === 0) return '-';
            if (val.includes(' %')) parseFloat(val.replace(' %').replace(/,/g, '')) + ' %';
            return parseFloat(val.replace(/,/g, ''));
        };
        const setCell = (cell, value, fill, font, numFmt, alignment, border) => {
            cell.value = value;
            cell.fill = fill;
            cell.font = font;
            cell.numFmt = numFmt;
            cell.alignment = alignment;
            cell.border = border;
        };

        let zip = new JSZip();
        for(let f = 0; f < bdgs.length; f++){
            let workbook = new ExcelJS.Workbook();
            cmp.set("v.d5filter", bdgs[f]);

            // refresh data from the source
            let origin = JSON.parse(JSON.stringify(cmp.get("v.rowsOriginal")));

            let columns = JSON.parse(JSON.stringify(cmp.get("v.reportColumnsOriginal")));
            cmp.set("v.reportColumns", columns);

            let header = JSON.parse(JSON.stringify(cmp.get("v.tableHeadersOriginal")));
            cmp.set("v.tableHeaders", header);
            let n = cmp.get("v.numberOfTextColumns"); // the number of text columns
            cmp.set("v.rows", origin);
            h.helpApplyDimensionFilter(cmp); // dimension filter
            if (cmp.get("v.rows").length === 0) {
                continue;
            }
            h.helpCalculateColumnTotals(cmp); // vertical totals
            h.helpCalculateRowTotals(cmp); // horizontal total

            h.helpFormatNumbers(cmp); // formatting

            h.helpShowHideSimpleRows(cmp); // total rows only filter
            h.helpApplyColumnsFilter(cmp); // display only allowed columns filter
            /////// ADD SHEET TO EXCELL
            let tableRows = h.restructureLines(JSON.parse(JSON.stringify(cmp.get('v.rows'))));
            let sheetName = bdgs[f];

            let fixedColumns = report.cb4__FixedColumns__c;
            if (_isInvalid(fixedColumns)) fixedColumns = 1; else fixedColumns--;
            let tableHeaders = cmp.get("v.tableHeaders");
            let bdgI = cmp.get('v.bdgI');

            for (let i = 0; i < tableHeaders.length; i++) {
                if (tableHeaders[i] === "BDG") {
                    bdgI = i;
                    cmp.set('v.bdgI', bdgI);
                }
            }
            if (bdgI !== null){
                if(tableHeaders[bdgI] ==='BDG')	{
                    tableHeaders.splice(bdgI, 1);
                }
                n--;
            }
            sheetName = sheetName.substring(0, 30).replace(':', '\uA789');
            const worksheet = workbook.addWorksheet(sheetName, {
                views: [
                    {state: 'frozen', ySplit: 6, xSplit: fixedColumns, showGridLines: false}
                ]
            });
            worksheet.getCell('A1').font = {
                name: 'Calibri',
                family: 4
            };
            /** LINE OVER HEADER **/
            const overHeaderTitlesRow = worksheet.getRow(5); // header row position from top
            worksheet.mergeCells(5, 1, 5, 4); // merge by start row, start column, end row, end column (equivalent to A1:D1)
            worksheet.mergeCells(5, 5, 5, 9); // merge by start row, start column, end row, end column (equivalent to E5:K5)
            worksheet.mergeCells(5, 10, 5, 14); // merge by start row, start column, end row, end column (equivalent to L5:Q5)
            worksheet.mergeCells(5, 15, 5, 17); // merge by start row, start column, end row, end column (equivalent to R5:T5)
            setCell(overHeaderTitlesRow.getCell(5), 'Current Month', h.overHeaderHeaderFill, h.overHeaderHeaderFont, null, h.headerTitleAlign, h.borderTopBottom);
            setCell(overHeaderTitlesRow.getCell(10), 'YTD', h.overHeaderHeaderFill, h.overHeaderHeaderFont, null, h.headerTitleAlign, h.borderTopBottom);
            setCell(overHeaderTitlesRow.getCell(15), '12 Months', h.overHeaderHeaderFill, h.overHeaderHeaderFont, null, h.headerTitleAlign, h.borderTopBottom);
            /** LINE OVER HEADER **/
            /** HEADERS  Reporting Dep	Type	Subtype ....**/
            const headerTitlesRow = worksheet.getRow(6); // header row position from top
            headerTitlesRow.height = 50;
            headerTitlesRow.values = tableHeaders; // header values like ['Reporting Dep', 'Type', 'Subtype' ....]
            headerTitlesRow.eachCell({includeEmpty: true}, (cell, i) => setCell(cell, i <= 3 ? '' : cell.value, h.headerFill, h.totalFont, null, h.headerTitleAlign, h.borderTopBottom)); // header styles
            /** HEADERS  Reporting Dep	Type	Subtype ....**/
                // ROWS
            const departmentName = {};
            const subtotalTypes = ['total', 'topHeader'];
            for (let idx = 1; idx <= 5; idx++) subtotalTypes.push(`subTotal${idx}`);
            let amountRowPosition = 7; // start position is 6
            let cellPosition;
            let subtotalFillMap = {
                subTotal1: h.overHeaderHeaderFill,
                subTotal2: h.overHeaderHeaderFill,
                subTotal3: h.subTotal3Fill,
                total: h.topHeaderFill,
                topHeader: h.topHeaderFill,
            };
            tableRows.forEach(row => {
                try {
                    const excelRow = worksheet.getRow(amountRowPosition); // one row
                    amountRowPosition++;
                    cellPosition = 1;
                    const rowIsSubTotal = subtotalTypes.includes(row.type);
                    const subtotalFill = row.type ? subtotalFillMap[row.type] : undefined;
                    const subtotalFont = row.type === 'subTotal1' || row.type === 'subTotal2' ? h.overHeaderHeaderFont : (row.type === 'total' ? h.totalFont : h.generalFont);

                    departmentName[row[`l1Long`]] = true; // collection of department names
                    if (row.type === 'topHeader') excelRow.height = 23;
                    for (let j = 0; j < n; j++) {
                        const cell = excelRow.getCell(cellPosition++);
                        let value = row[`l${j + 1}Long`];
                        if (rowIsSubTotal) {
                            value = value === '-' ? null : value;
                            setCell(cell, value, subtotalFill, subtotalFont, null, h.rowTitleAlign, h.borderTopBottom);
                        } else {
                            setCell(cell, value, null, h.simpleFont);
                        }
                    }// text part of a row

                    row.v.forEach((val, idx) => {
                        const cell = excelRow.getCell(cellPosition++);
                        const value = row.type === 'topHeader' ? '' : getRowAmount(val);
                        if (rowIsSubTotal) {
                            if(row.type !== 'topHeader') setCell(cell, value, subtotalFill, subtotalFont, h.NUM_FORMAT, h.decAlign, h.borderTopBottom);
                            else setCell(cell, value, subtotalFill, subtotalFont, '@', h.decAlign, h.borderTopBottom);
                        } else {
                            setCell(cell, value, null, h.simpleFont, h.NUM_FORMAT, h.decAlign);
                        }
                    });
                } catch (e) {
                    alert('ERROR: ' + e);
                }
            });
            h.setColumnsWidth(worksheet);
            h.makeTransparentExtraExcelTitles(worksheet, tableRows);
            ['TOTAL', 'EXPENSE', 'REVENUE'].forEach(title => delete departmentName[title]);
            h.addReportHeaderLines(worksheet, customFormat, Object.keys(departmentName).join(', '), cmp.get('v.displayedColumns'));
            h.addVerticalBorders(worksheet, tableRows.length);
            worksheet.autoFilter = 'A5:D5';
            const xlsFile = workbook.xlsx.writeBuffer();
            zip.file(sheetName + '.xlsx', xlsFile, {binary: true});
        }
        zip.generateAsync({type:"blob"}).then(function(content) {saveAs(content, 'BDG ' + cmp.get('v.report').Name + ".zip");});
        _hideSpinner(cmp);
    },
    downloadExcel: function (cmp, event, helper) {
        helper.helpDownloadExcel(cmp);
    },
    downloadAllToExcel: function (cmp, evt, h) {
        // helper.helpDownloadAllToExcel(cmp); //All BRD in one sheet

        /*All BRD in separate excel files*/
        let report = cmp.get("v.report");
        const customFormat = report.cb4__Description__c === 'Custom Excel';
        let repDepartments = cmp.get('v.d1SO');
        cmp.set("v.d2filter", null);
        cmp.set("v.d3filter", null);
        cmp.set("v.d4filter", null);
        cmp.set("v.d5filter", null);
        cmp.set("v.d6filter", null);
        cmp.set("v.d7filter", null);

        const getRowAmount = (val) => {
            if (val === '-' || val.includes('%')) return val;
            if (parseInt(val.replace(' %').replace(/,/g, '')) === 0) return '-';
            if (val.includes(' %')) parseFloat(val.replace(' %').replace(/,/g, '')) + ' %';
            return parseFloat(val.replace(/,/g, ''));
        };
        const setCell = (cell, value, fill, font, numFmt, alignment, border) => {
            cell.value = value;
            cell.fill = fill;
            cell.font = font;
            cell.numFmt = numFmt;
            cell.alignment = alignment;
            cell.border = border;
        };

        let zip = new JSZip();
        for(let f = 0; f < repDepartments.length; f++){
            let workbook = new ExcelJS.Workbook();
            cmp.set("v.d1filter", repDepartments[f]);

            // refresh data from the source
            let origin = JSON.parse(JSON.stringify(cmp.get("v.rowsOriginal")));
            let columns = JSON.parse(JSON.stringify(cmp.get("v.reportColumnsOriginal")));
            cmp.set("v.reportColumns", columns);
            let header = JSON.parse(JSON.stringify(cmp.get("v.tableHeadersOriginal")));

            cmp.set("v.tableHeaders", header);
            let n = cmp.get("v.numberOfTextColumns"); // the number of text columns
            cmp.set("v.rows", origin);
            h.helpApplyDimensionFilter(cmp); // dimension filter
            if (cmp.get("v.rows").length === 0) {
                continue;
            }
            h.helpCalculateColumnTotals(cmp); // vertical totals
            h.helpCalculateRowTotals(cmp); // horizontal total

            h.helpFormatNumbers(cmp); // formatting

            h.helpShowHideSimpleRows(cmp); // total rows only filter
            h.helpApplyColumnsFilter(cmp); // display only allowed columns filter
            /////// ADD SHEET TO EXCELL
            let tableRows = h.restructureLines(JSON.parse(JSON.stringify(cmp.get('v.rows'))));
            let sheetName = repDepartments[f];

            let fixedColumns = report.cb4__FixedColumns__c;
            if (_isInvalid(fixedColumns)) fixedColumns = 1; else fixedColumns--;
            let tableHeaders = cmp.get("v.tableHeaders");
            let bdgI = cmp.get('v.bdgI');

            for (let i = 0; i < tableHeaders.length; i++) {
                if (tableHeaders[i] === "BDG") {
                    bdgI = i;
                    cmp.set('v.bdgI', bdgI);
                }
            }
            if (bdgI !== null){
                if(tableHeaders[bdgI] ==='BDG')	{
                    tableHeaders.splice(bdgI, 1);
                }
                n--;
            }
            sheetName = sheetName.replace(':', '\uA789');
            const worksheet = workbook.addWorksheet(sheetName, {
                views: [
                    {state: 'frozen', ySplit: 6, xSplit: fixedColumns, showGridLines: false}
                ]
            });
            worksheet.getCell('A1').font = {
                name: 'Calibri',
                family: 4
            };
            /** LINE OVER HEADER **/
            const overHeaderTitlesRow = worksheet.getRow(5); // header row position from top
            worksheet.mergeCells(5, 1, 5, 4); // merge by start row, start column, end row, end column (equivalent to A1:D1)
            worksheet.mergeCells(5, 5, 5, 9); // merge by start row, start column, end row, end column (equivalent to E5:K5)
            worksheet.mergeCells(5, 10, 5, 14); // merge by start row, start column, end row, end column (equivalent to L5:Q5)
            worksheet.mergeCells(5, 15, 5, 17); // merge by start row, start column, end row, end column (equivalent to R5:T5)
            setCell(overHeaderTitlesRow.getCell(5), 'Current Month', h.overHeaderHeaderFill, h.overHeaderHeaderFont, null, h.headerTitleAlign, h.borderTopBottom);
            setCell(overHeaderTitlesRow.getCell(10), 'YTD', h.overHeaderHeaderFill, h.overHeaderHeaderFont, null, h.headerTitleAlign, h.borderTopBottom);
            setCell(overHeaderTitlesRow.getCell(15), '12 Months', h.overHeaderHeaderFill, h.overHeaderHeaderFont, null, h.headerTitleAlign, h.borderTopBottom);
            /** LINE OVER HEADER **/
            /** HEADERS  Reporting Dep	Type	Subtype ....**/
            const headerTitlesRow = worksheet.getRow(6); // header row position from top
            headerTitlesRow.height = 50;
            headerTitlesRow.values = tableHeaders; // header values like ['Reporting Dep', 'Type', 'Subtype' ....]
            headerTitlesRow.eachCell({includeEmpty: true}, (cell, i) => setCell(cell, i <= 3 ? '' : cell.value, h.headerFill, h.totalFont, null, h.headerTitleAlign, h.borderTopBottom)); // header styles
            /** HEADERS  Reporting Dep	Type	Subtype ....**/
                // ROWS
            const departmentName = {};
            const subtotalTypes = ['total', 'topHeader'];
            for (let idx = 1; idx <= 5; idx++) subtotalTypes.push(`subTotal${idx}`);
            let amountRowPosition = 7; // start position is 6
            let cellPosition;
            let subtotalFillMap = {
                subTotal1: h.overHeaderHeaderFill,
                subTotal2: h.overHeaderHeaderFill,
                subTotal3: h.subTotal3Fill,
                total: h.topHeaderFill,
                topHeader: h.topHeaderFill,
            };
            tableRows.forEach(row => {
                try {
                    const excelRow = worksheet.getRow(amountRowPosition); // one row
                    amountRowPosition++;
                    cellPosition = 1;
                    const rowIsSubTotal = subtotalTypes.includes(row.type);
                    const subtotalFill = row.type ? subtotalFillMap[row.type] : undefined;
                    const subtotalFont = row.type === 'subTotal1' || row.type === 'subTotal2' ? h.overHeaderHeaderFont : (row.type === 'total' ? h.totalFont : h.generalFont);

                    departmentName[row[`l1Long`]] = true; // collection of department names
                    if (row.type === 'topHeader') excelRow.height = 23;
                    for (let j = 0; j < n; j++) {
                        const cell = excelRow.getCell(cellPosition++);
                        let value = row[`l${j + 1}Long`];
                        if (rowIsSubTotal) {
                            value = value === '-' ? null : value;
                            setCell(cell, value, subtotalFill, subtotalFont, null, h.rowTitleAlign, h.borderTopBottom);
                        } else {
                            setCell(cell, value, null, h.simpleFont);
                        }
                    }// text part of a row

                    row.v.forEach((val, idx) => {
                        const cell = excelRow.getCell(cellPosition++);
                        const value = row.type === 'topHeader' ? '' : getRowAmount(val);
                        if (rowIsSubTotal) {
                            if(row.type !== 'topHeader') setCell(cell, value, subtotalFill, subtotalFont, h.NUM_FORMAT, h.decAlign, h.borderTopBottom);
                            else setCell(cell, value, subtotalFill, subtotalFont, '@', h.decAlign, h.borderTopBottom);
                        } else {
                            setCell(cell, value, null, h.simpleFont, h.NUM_FORMAT, h.decAlign);
                        }
                    });
                } catch (e) {
                    alert('ERROR: ' + e);
                }
            });
            h.setColumnsWidth(worksheet);
            h.makeTransparentExtraExcelTitles(worksheet, tableRows);
            ['TOTAL', 'EXPENSE', 'REVENUE'].forEach(title => delete departmentName[title]);
            h.addReportHeaderLines(worksheet, customFormat, Object.keys(departmentName).join(', '), cmp.get('v.displayedColumns'));
            h.addVerticalBorders(worksheet, tableRows.length);
            worksheet.autoFilter = 'A5:D5';
            const xlsFile = workbook.xlsx.writeBuffer();
            zip.file(sheetName + '.xlsx', xlsFile, {binary: true});
        }
        zip.generateAsync({type:"blob"}).then(function(content) {saveAs(content, cmp.get('v.report').Name + ".zip");});
        _hideSpinner(cmp);
    },
    downloadAllBySheetToExcel: function (cmp, evt, h) {
        let report = cmp.get("v.report");
        const customFormat = report.cb4__Description__c === 'Custom Excel';
        let workbook = new ExcelJS.Workbook();
        let repDepartments = cmp.get('v.d1SO');
        cmp.set("v.d2filter", null);
        cmp.set("v.d3filter", null);
        cmp.set("v.d4filter", null);
        cmp.set("v.d5filter", null);
        cmp.set("v.d6filter", null);
        cmp.set("v.d7filter", null);

        const getRowAmount = (val) => {
            if (val === '-' || val.includes('%')) return val;
            if (parseInt(val.replace(' %').replace(/,/g, '')) === 0) return '-';
            if (val.includes(' %')) parseFloat(val.replace(' %').replace(/,/g, '')) + ' %';
            return parseFloat(val.replace(/,/g, ''));
        };
        const setCell = (cell, value, fill, font, numFmt, alignment, border) => {
            cell.value = value;
            cell.fill = fill;
            cell.font = font;
            cell.numFmt = numFmt;
            cell.alignment = alignment;
            cell.border = border;
        };
        for(let f = 0; f < repDepartments.length; f++){
            cmp.set("v.d1filter", repDepartments[f]);

            // refresh data from the source
            let origin = JSON.parse(JSON.stringify(cmp.get("v.rowsOriginal")));

            let columns = JSON.parse(JSON.stringify(cmp.get("v.reportColumnsOriginal")));
            cmp.set("v.reportColumns", columns);

            let header = JSON.parse(JSON.stringify(cmp.get("v.tableHeadersOriginal")));
            cmp.set("v.tableHeaders", header);
            let n = cmp.get("v.numberOfTextColumns"); // the number of text columns
            cmp.set("v.rows", origin);
            h.helpApplyDimensionFilter(cmp); // dimension filter
            if (cmp.get("v.rows").length === 0) {
                continue;
            }
            h.helpCalculateColumnTotals(cmp); // vertical totals
            h.helpCalculateRowTotals(cmp); // horizontal total

            h.helpFormatNumbers(cmp); // formatting

            h.helpShowHideSimpleRows(cmp); // total rows only filter
            h.helpApplyColumnsFilter(cmp); // display only allowed columns filter
            /////// ADD SHEET TO EXCELL
            let tableRows = h.restructureLines(JSON.parse(JSON.stringify(cmp.get('v.rows'))));
            let sheetName = repDepartments[f];

            let fixedColumns = report.cb4__FixedColumns__c;
            if (_isInvalid(fixedColumns)) fixedColumns = 1; else fixedColumns--;
            let tableHeaders = cmp.get("v.tableHeaders");
            let bdgI = cmp.get('v.bdgI');

            for (let i = 0; i < tableHeaders.length; i++) {
                if (tableHeaders[i] === "BDG") {
                    bdgI = i;
                    cmp.set('v.bdgI', bdgI);
                }
            }
            if (bdgI !== null){
                if(tableHeaders[bdgI] ==='BDG')	{
                    tableHeaders.splice(bdgI, 1);
                }
                n--;
            }
            sheetName = sheetName.substring(0, 30).replace(':', '\uA789');
            const worksheet = workbook.addWorksheet(sheetName, {
                views: [
                    {state: 'frozen', ySplit: 6, xSplit: fixedColumns, showGridLines: false}
                ]
            });
            worksheet.getCell('A1').font = {
                name: 'Calibri',
                family: 4
            };
            /** LINE OVER HEADER **/
            const overHeaderTitlesRow = worksheet.getRow(5); // header row position from top
            worksheet.mergeCells(5, 1, 5, 4); // merge by start row, start column, end row, end column (equivalent to A1:D1)
            worksheet.mergeCells(5, 5, 5, 9); // merge by start row, start column, end row, end column (equivalent to E5:K5)
            worksheet.mergeCells(5, 10, 5, 14); // merge by start row, start column, end row, end column (equivalent to L5:Q5)
            worksheet.mergeCells(5, 15, 5, 17); // merge by start row, start column, end row, end column (equivalent to R5:T5)
            setCell(overHeaderTitlesRow.getCell(5), 'Current Month', h.overHeaderHeaderFill, h.overHeaderHeaderFont, null, h.headerTitleAlign, h.borderTopBottom);
            setCell(overHeaderTitlesRow.getCell(10), 'YTD', h.overHeaderHeaderFill, h.overHeaderHeaderFont, null, h.headerTitleAlign, h.borderTopBottom);
            setCell(overHeaderTitlesRow.getCell(15), '12 Months', h.overHeaderHeaderFill, h.overHeaderHeaderFont, null, h.headerTitleAlign, h.borderTopBottom);
            /** LINE OVER HEADER **/
            /** HEADERS  Reporting Dep	Type	Subtype ....**/
            const headerTitlesRow = worksheet.getRow(6); // header row position from top
            headerTitlesRow.height = 50;
            headerTitlesRow.values = tableHeaders; // header values like ['Reporting Dep', 'Type', 'Subtype' ....]
            headerTitlesRow.eachCell({includeEmpty: true}, (cell, i) => setCell(cell, i <= 3 ? '' : cell.value, h.headerFill, h.totalFont, null, h.headerTitleAlign, h.borderTopBottom)); // header styles
            /** HEADERS  Reporting Dep	Type	Subtype ....**/
                // ROWS
            const departmentName = {};
            const subtotalTypes = ['total', 'topHeader'];
            for (let idx = 1; idx <= 5; idx++) subtotalTypes.push(`subTotal${idx}`);
            let amountRowPosition = 7; // start position is 6
            let cellPosition;
            let subtotalFillMap = {
                subTotal1: h.overHeaderHeaderFill,
                subTotal2: h.overHeaderHeaderFill,
                subTotal3: h.subTotal3Fill,
                total: h.topHeaderFill,
                topHeader: h.topHeaderFill,
            };
            tableRows.forEach(row => {
                try {
                    const excelRow = worksheet.getRow(amountRowPosition); // one row
                    amountRowPosition++;
                    cellPosition = 1;
                    const rowIsSubTotal = subtotalTypes.includes(row.type);
                    const subtotalFill = row.type ? subtotalFillMap[row.type] : undefined;
                    const subtotalFont = row.type === 'subTotal1' || row.type === 'subTotal2' ? h.overHeaderHeaderFont : (row.type === 'total' ? h.totalFont : h.generalFont);

                    departmentName[row[`l1Long`]] = true; // collection of department names
                    if (row.type === 'topHeader') excelRow.height = 23;
                    for (let j = 0; j < n; j++) {
                        const cell = excelRow.getCell(cellPosition++);
                        let value = row[`l${j + 1}Long`];
                        if (rowIsSubTotal) {
                            value = value === '-' ? null : value;
                            setCell(cell, value, subtotalFill, subtotalFont, null, h.rowTitleAlign, h.borderTopBottom);
                        } else {
                            setCell(cell, value, null, h.simpleFont);
                        }
                    }// text part of a row

                    row.v.forEach((val, idx) => {
                        const cell = excelRow.getCell(cellPosition++);
                        const value = row.type === 'topHeader' ? '' : getRowAmount(val);
                        if (rowIsSubTotal) {
                            if(row.type !== 'topHeader') setCell(cell, value, subtotalFill, subtotalFont, h.NUM_FORMAT, h.decAlign, h.borderTopBottom);
                            else setCell(cell, value, subtotalFill, subtotalFont, '@', h.decAlign, h.borderTopBottom);
                        } else {
                            setCell(cell, value, null, h.simpleFont, h.NUM_FORMAT, h.decAlign);
                        }
                    });
                } catch (e) {
                    alert('ERROR: ' + e);
                }
            });
            h.setColumnsWidth(worksheet);
            h.makeTransparentExtraExcelTitles(worksheet, tableRows);
            ['TOTAL', 'EXPENSE', 'REVENUE'].forEach(title => delete departmentName[title]);
            h.addReportHeaderLines(worksheet, customFormat, Object.keys(departmentName).join(', '), cmp.get('v.displayedColumns'));
            h.addVerticalBorders(worksheet, tableRows.length);
            worksheet.autoFilter = 'A5:D5';
        }
        workbook.xlsx.writeBuffer().then(buffer => saveAs(new Blob([buffer]), cmp.get('v.report.Name') + '.xlsx')).catch(err => alert('Error writing excel export', err));
        _hideSpinner(cmp);
    },
    downloadPDF: function (cmp, event, helper) {
        helper.helpDownloadPDF(cmp);
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